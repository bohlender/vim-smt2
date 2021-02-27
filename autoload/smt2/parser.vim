let s:debug = v:false

" TODO: Check & follow some vimscript styleguide
" TODO: Support formatting of answers. Must parse non-SExpr (e.g. unsat, error)
" TODO: Error handling if parsing fails, e.g. via expectation tokens?
" TODO: Use [:space:] instead of \_s?
" TODO: Cache parsers?

" ------------------------------------------------------------------------------
" Generic parser builders
" ------------------------------------------------------------------------------
function! s:StartsWith(pattern, OnMatch = {val -> v:none})
        return funcref('ParseStartsWith', [a:pattern, a:OnMatch])
endfunction

function! ParseStartsWith(pattern, OnMatch, pos) abort
    let cur_pos = matchend(s:input, '\m\C^' . a:pattern, a:pos)
    if cur_pos == -1
        return s:Fail(a:pos)
    endif
    return s:Success(cur_pos, a:OnMatch(s:input[a:pos:cur_pos-1]))
endfunction


function! s:Choice(...)
    let parsers = a:000
    return funcref('ParseChoice', [parsers])
endfunction

function! ParseChoice(Parsers, pos) abort
    if s:debug | call s:Debug(a:pos, 'Choice') | endif
    for Parser in a:Parsers
       let res = Parser(a:pos)
       if res.succ
            return s:Success(res.pos, res.val)
       endif
    endfor
    return s:Fail(a:pos)
endfunction


function! s:Seq(...)
    let parsers = a:000
    return funcref('ParseSeq', [parsers])
endfunction

function! ParseSeq(Parsers, pos) abort
    if s:debug | call s:Debug(a:pos, 'Seq') | endif
    let cur_pos = a:pos
    let val = []
    for Parser in a:Parsers
        let res = Parser(cur_pos)
        if !res.succ
            return s:Fail(a:pos)
        endif
        let cur_pos = res.pos
        call add(val, res.val)
    endfor
    return s:Success(cur_pos, val)
endfunction


function! s:ZeroOrMore(Parser)
    return funcref('ParseZeroOrMore', [a:Parser])
endfunction

function! ParseZeroOrMore(Parser, pos) abort
    if s:debug | call s:Debug(a:pos, 'ParseZeroOrMore') | endif
    let cur_pos = a:pos
    let val = []
    while v:true
        let res = a:Parser(cur_pos)
        if !res.succ
            break
        endif
        let cur_pos = res.pos
        call add(val, res.val)
    endwhile
    return s:Success(cur_pos, val)
endfunction


function! s:OneOrMore(Parser)
    return funcref('ParseOneOrMore', [a:Parser])
endfunction

function! ParseOneOrMore(Parser, pos) abort
    if s:debug | call s:Debug(a:pos, 'ParseOneOrMore') | endif
    let cur_pos = a:pos

    " Must match once
    let first_res = a:Parser(cur_pos)
    if !first_res.succ
        return s:Fail(a:pos)
    endif
    let cur_pos = first_res.pos

    " Further matches are optional
    let further_res = s:ZeroOrMore(a:Parser)(cur_pos)
    return s:Success(further_res.pos, [first_res.val] + further_res.val)
endfunction


" ------------------------------------------------------------------------------
" Specific parsers
" ------------------------------------------------------------------------------
" Paragraph ::= (Comment | SExpr)+
" SExpr     ::= '(' Expr* ')'
" Expr      ::= Comment | SExpr | Atom
" Atom      ::= quoted | symbol

function! s:LParen()
    return funcref('ParseLParen')
endfunction

function! ParseLParen(pos) abort
    if s:debug | call s:Debug(a:pos, 'LParen') | endif
    let Parser = s:StartsWith('\_s*(')
    return Parser(a:pos)
endfunction


function! s:RParen()
    return funcref('ParseRParen')
endfunction

function! ParseRParen(pos) abort
    if s:debug | call s:Debug(a:pos, 'RParen') | endif
    let Parser = s:StartsWith('\_s*)')
    return Parser(a:pos)
endfunction


function! s:Paragraph()
    return funcref('ParseParagraph')
endfunction

function! ParseParagraph(pos) abort
    if s:debug | call s:Debug(a:pos, 'Paragraph') | endif
    let Parser = s:OneOrMore(s:Choice(s:Comment(), s:SExpr()))
    let res = Parser(a:pos)
    if res.succ
        let res.val = s:AST('Paragraph', res.val)
    endif
    return res
endfunction


" TODO: Make sure "\n" linebreak in regex works on windows / with other encodings
function! s:Comment()
    return funcref('ParseComment')
endfunction

function! ParseComment(pos) abort
    if s:debug | call s:Debug(a:pos, 'Comment') | endif
    let Parser = s:StartsWith('\_s*;[^\n]*', {val -> s:AST('Comment', trim(val))})
    return Parser(a:pos)
endfunction


function! s:SExpr()
    return funcref('ParseSExpr')
endfunction

function! ParseSExpr(pos) abort
    if s:debug | call s:Debug(a:pos, 'SExpr') | endif
    let Parser = s:Seq(s:LParen(), s:ZeroOrMore(s:Expr()), s:RParen())
    let res = Parser(a:pos)

    " Ignore parens; return the Expr list
    if res.succ
        let res.val = s:AST('SExpr', res.val[1])
    endif
    return res
endfunction


function! s:Expr()
    return funcref('ParseExpr')
endfunction

function! ParseExpr(pos) abort
    if s:debug | call s:Debug(a:pos, 'Expr') | endif
    let Parser = s:Choice(s:Comment(), s:SExpr(), s:Atom())
    return Parser(a:pos)
endfunction


function! s:Atom()
    return funcref('ParseAtom')
endfunction

function! ParseAtom(pos) abort
    if s:debug | call s:Debug(a:pos, 'Atom') | endif

    " Quoted string (may even contain '(' or ')')
    let Quoted = s:StartsWith('\_s*".*"', {val -> trim(val)})

    " All but whitespace, '(' or ')'
    let Symbol = s:StartsWith('\_s*[^[:space:]()]\+', {val -> trim(val)})

    let Parser = s:Choice(Quoted, Symbol)
    let res = Parser(a:pos)
    if res.succ
        let res.val = s:AST('Atom', res.val)
    endif
    return res
endfunction

" ------------------------------------------------------------------------------
" Helpers
" ------------------------------------------------------------------------------
function! s:Debug(pos, fname)
    echom "Pos " . a:pos . ": '" . s:input[a:pos:a:pos+10] . "'" . ", Parser: " . a:fname
endfunction

" AST nodes & printing (for debug purposes)
function! s:AST(kind, value)
    return {'kind': a:kind, 'value': a:value}
endfunction

function! s:PrintAst(ast, indent = 0)
    echo repeat(' ', a:indent*2) . '[' . a:ast.kind . '] '

    if type(a:ast.value) == type([])
        for val in a:ast.value
            call s:PrintAst(val, a:indent+1)
        endfor
    elseif type(a:ast.value) == type({})
        call s:PrintAst(a:ast.value, a:indent+1)
    else
        echon a:ast.value
    endif
endfunction

" Parse results are effectively tuples: (success, position in s:input, return value)
function! s:Fail(pos)
    return {'succ': v:false, 'pos': a:pos}
endfunction

function! s:Success(pos, value)
    return {'succ': v:true, 'pos': a:pos, 'val': a:value}
endfunction

" Fetch paragraphs to format
function! s:GetAllParagraphs()
    let content = join(getline(1, '$'), "\n")
    let paragraphs = split(content, '\m\C\n\{2,}')
    return paragraphs
endfunction

function! s:GetCurrentParagraph()
    let cursor = getpos('.')
    silent! normal! {"0y}
    call setpos('.', cursor)
    return trim(@0)
endfunction

" ------------------------------------------------------------------------------
" Public functions
" ------------------------------------------------------------------------------
" Note: `input` and `pos` are script-global and accessed by all parsers

function! smt2#parser#ParseCurrentParagraph() abort
    let s:input = s:GetCurrentParagraph()
    let s:pos = 0

    let Parser = s:Paragraph()
    let res = Parser(s:pos)

    if s:debug | call s:PrintAst(res.val) | endif
    return res.val
endfunction

function! smt2#parser#ParseAllParagraphs() abort
    let paragraphs = s:GetAllParagraphs()

    let Parser = s:Paragraph()
    let asts = []
    for s:input in paragraphs
        let s:pos = 0

        if s:debug
            echo "\nParagraph\n========="
            echo s:input
            echo "\nParsing\n======="
        endif

        let res = Parser(s:pos)
        call add(asts, res.val)

        if s:debug
            echo "\nAST\n==="
            call s:PrintAst(res.val)
            echo "\n"
        endif
    endfor
    return asts
endfunction
