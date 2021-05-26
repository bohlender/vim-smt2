vim9script
const debug = true
set maxfuncdepth=100000000 # SMT files tend to be highly nested

# TODO: Make parse status a boolean
# TODO: Support formatting of answers. Must parse non-SExpr (e.g. unsat, error)
# TODO: Error handling if parsing fails, e.g. via expectation tokens?
# TODO: Retry iterative parsing now that we have a scanner and simpler grammar
# TODO: Refer to token kind by name, e.g. token_comment instead of 8
# TODO: Change Ast.kind type from string to enum/number?

# ------------------------------------------------------------------------------
# AST nodes (essentially named token wrappers)
# ------------------------------------------------------------------------------
def Ast(kind: string, value: any): dict<any>
    return {kind: kind, value: value}
enddef

def ParagraphAst(tokens: list<dict<any>>): dict<any>
    return Ast('Paragraph', tokens)
enddef

def SExprAst(tokens: list<dict<any>>): dict<any>
    return Ast('SExpr', tokens)
enddef

def AtomAst(token: dict<any>): dict<any>
    return Ast('Atom', token)
enddef

def PrintAst(ast: dict<any>, indent = 0)
    echo repeat(' ', indent * 2) .. '[' .. ast.kind .. '] '

    if ast.kind ==# 'Atom'
        echon ast.value.lexeme
    elseif ast.kind ==# 'SExpr'
        for v in ast.value
            call PrintAst(v, indent + 1)
        endfor
    elseif ast.kind ==# 'Paragraph'
        for v in ast.value
            call PrintAst(v, indent + 1)
        endfor
    endif
enddef

# ------------------------------------------------------------------------------
# Parse status
# ------------------------------------------------------------------------------

# Parse status enumeration
const status_success = 0
const status_fail = 1

# Parse result (status, position in token list, return value)
def Fail(pos: number): dict<any>
    return {status: status_fail, pos: pos}
enddef

def Success(pos: number, value: any): dict<any>
    return {status: status_success, pos: pos, value: value}
enddef

# ------------------------------------------------------------------------------
# Grammar / concrete parsers
# ------------------------------------------------------------------------------
# Paragraph ::= Expr+
# Expr      ::= SExpr | Atom
# SExpr     ::= '(' Expr* ')'

def ParseLParen(tokens: list<dict<any>>, pos: number): dict<any>
    if pos < len(tokens) && tokens[pos].kind == 0
        return Success(pos + 1, v:none)
    endif
    return Fail(pos)
enddef

def ParseRParen(tokens: list<dict<any>>, pos: number): dict<any>
    if pos < len(tokens) && tokens[pos].kind == 1
        return Success(pos + 1, v:none)
    endif
    return Fail(pos)
enddef

def ParseAtom(tokens: list<dict<any>>, pos: number): dict<any>
    if pos < len(tokens)
        const token = tokens[pos]
        if 2 <= token.kind && token.kind <= 8
            return Success(pos + 1, AtomAst(token))
        endif
    endif
    return Fail(pos)
enddef

def ParseExpr(tokens: list<dict<any>>, pos: number): dict<any>
    var res = ParseSExpr(tokens, pos)
    if res.status == status_success
        return res
    endif

    return ParseAtom(tokens, pos)
enddef

#def ParseNOrMoreExpr(n: number, tokens: list<dict<any>>, pos: number): dict<any>
#    var exprs: list<any>
#    var match_count = 0
#    var cur_pos = pos
#    while true
#        var res = ParseExpr(tokens, cur_pos)
#        if res.status == status_success
#            match_count += 1
#            cur_pos = res.pos
#            exprs->add(res.value)
#        else
#            break
#        endif
#    endwhile
#    if match_count < n
#        return Fail(pos)
#    endif
#    return Success(cur_pos, exprs)
#enddef

def ParseSExpr(tokens: list<dict<any>>, pos: number): dict<any>
    var res = ParseLParen(tokens, pos)
    if res.status == status_fail
        return Fail(pos)
    endif

    # Inlined ParseNOrMoreExpr(0, tokens, res.pos)
    var exprs: list<any>
    var cur_pos = res.pos
    while true
        res = ParseExpr(tokens, cur_pos)
        if res.status == status_success
            cur_pos = res.pos
            exprs->add(res.value)
        else
            break
        endif
    endwhile

    res = ParseRParen(tokens, cur_pos)
    if res.status == status_fail
        return Fail(pos)
    endif

    return Success(res.pos, SExprAst(exprs))
enddef

def ParseParagraph(tokens: list<dict<any>>, pos = 0): dict<any>
    # Inlined ParseNOrMoreExpr(1, tokens, res.pos)
    var exprs: list<any>
    var matched = false
    var cur_pos = pos
    while true
        var res = ParseExpr(tokens, cur_pos)
        if res.status == status_success
            matched = true
            cur_pos = res.pos
            exprs->add(res.value)
        else
            break
        endif
    endwhile
    if !matched
        return Fail(pos)
    endif
    return Success(cur_pos, ParagraphAst(exprs))
enddef

# ------------------------------------------------------------------------------
# Fetch paragraphs to format
# ------------------------------------------------------------------------------
# TODO: Splitting by \n{2,} may break up quoted (multiline) symbols
def GetAllParagraphs(): list<string>
    const content = join(getline(1, '$'), "\n")
    const paragraphs = split(content, '\m\C\n\{2,}')
    return paragraphs
enddef

def GetCurrentParagraph(): string
    const cursor = getpos('.')
    silent! normal! {"0y}
    call setpos('.', cursor)
    return trim(@0)
enddef

# ------------------------------------------------------------------------------
# Public functions
# ------------------------------------------------------------------------------
def smt2#parser#ParseCurrentParagraph(): dict<any>
    const source = GetCurrentParagraph()
    const tokens = smt2#scanner#ScanSource(source)
    const res = tokens->ParseParagraph()

    if debug | res.value->PrintAst() | endif
    return res.value
enddef

def smt2#parser#ParseAllParagraphs(): list<dict<any>>
    const paragraphs = GetAllParagraphs()

    var asts = []
    for source in paragraphs
        const tokens = smt2#scanner#ScanSource(source)
        const res = tokens->ParseParagraph()
        asts->add(res.value)

        if debug | res.value->PrintAst() | endif
    endfor
    return asts
enddef
