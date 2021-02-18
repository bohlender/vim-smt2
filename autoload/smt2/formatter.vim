" ------------------------------------------------------------------------------
" Config
" ------------------------------------------------------------------------------
" Length of "short" S-expressions
if !exists("g:smt2_formatter_short_length")
    let g:smt2_formatter_short_length = 80
endif

" String to use for indentation
if !exists("g:smt2_formatter_indent_str")
    let g:smt2_formatter_indent_str = '  '
endif

" ------------------------------------------------------------------------------
" Formatter
" ------------------------------------------------------------------------------
function! s:FormatOneLine(ast, in_sexpr = v:false) abort
    if a:ast.kind ==? 'Comment'
        " Comments in a SExpr cannot fit in one line (they consume \n)
        if a:in_sexpr
            return s:Fail()
        endif
        return s:Success(a:ast.value)
    elseif a:ast.kind ==? 'Atom'
        return s:Success(a:ast.value)
    elseif a:ast.kind ==? 'SExpr'
        let formatted = []
        for expr in a:ast.value
            let res = s:FormatOneLine(expr, v:true)
            if !res.succ
                return s:Fail()
            endif
            call add(formatted, res.val)
        endfor
        return s:Success('(' . join(formatted, ' ') . ')')
    elseif a:ast.kind ==? 'Paragraph'
        " Multi-line paragraph cannot fit on one line
        if len(a:ast.value) != 1
            return s:Fail()
        endif
        return s:FormatOneLine(a:ast.value[0])
    else
        echoerr 'Cannot format AST node: ' . string(a:ast)
    endif
endfunction

function! s:Format(ast, indent = 0) abort
    let indent_str = repeat(g:smt2_formatter_indent_str, a:indent)

    if a:ast.kind ==? 'Comment'
        return indent_str . a:ast.value
    elseif a:ast.kind ==? 'Atom'
        return indent_str . a:ast.value
    elseif a:ast.kind ==? 'SExpr'
        " Short expression -- avoid line breaks
        let oneline_res = s:FormatOneLine(a:ast, v:true)
        if oneline_res.succ && len(oneline_res.val) < g:smt2_formatter_short_length
            return indent_str . oneline_res.val
        endif

        " Long expression -- break lines and indent subexpressions.
        " Don't break before first subexpression if it's a comment or atom
        let formatted = []
        if (a:ast.value[0].kind ==? 'Comment' || a:ast.value[0].kind ==? 'Atom')
            call add(formatted, s:Format(a:ast.value[0], 0))
        else
            call add(formatted, "\n" . s:Format(a:ast.value[0], a:indent+1))
        endif
        for child in a:ast.value[1:]
            call add(formatted, s:Format(child, a:indent+1))
        endfor
        return indent_str . "(" . join(formatted, "\n") . ")"
    elseif a:ast.kind ==? 'Paragraph'
        let formatted = []
        for child in a:ast.value
            call add(formatted, s:Format(child))
        endfor
        return join(formatted, "\n")
    else
        echoerr 'Cannot format AST node: ' . string(a:ast)
    endif
endfunction

function! s:Fail()
    return {'succ': v:false}
endfunction

function! s:Success(val)
    return {'succ': v:true, 'val': a:val}
endfunction

" ------------------------------------------------------------------------------
" Public functions
" ------------------------------------------------------------------------------
function! smt2#formatter#FormatAllParagraphs()
    let cursor = getpos('.')
    let asts = smt2#parser#ParseAllParagraphs()

    " Clear buffer & insert formatted paragraphs
    1,$delete
    for ast in asts
        let lines = split(s:Format(ast), '\n')
        call append('$', lines)
        call append('$', '')
    endfor

    " Remove first & trailing empty lines
    1delete
    $delete

    " Restore cursor position
    call setpos('.', cursor)
endfunction
