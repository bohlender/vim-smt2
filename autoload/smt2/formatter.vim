" Formatting requires a rather recent Vim version
if !has("vim9script")
    const s:errmsg_oldvim = "Auto-formatting requires a Vim version with vim9script support."

    "Dummies
    function! smt2#formatter#FormatCurrentParagraph()
        echoerr s:errmsg_oldvim
    endfunction
    function! smt2#formatter#FormatOutermostSExpr()
        echoerr s:errmsg_oldvim
    endfunction
    function! smt2#formatter#FormatFile()
        echoerr s:errmsg_oldvim
    endfunction

    finish
endif
vim9script
import "./scanner.vim" as scanner_ns
import "./parser.vim"

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------
# Length of "short" S-expressions
if !exists("g:smt2_formatter_short_length")
    g:smt2_formatter_short_length = 80
endif

# String to use for indentation
if !exists("g:smt2_formatter_indent_str")
    g:smt2_formatter_indent_str = '  '
endif

# ------------------------------------------------------------------------------
# Formatter
# ------------------------------------------------------------------------------
def FitsOneLine(ast: parser.Ast): bool
    # A paragraph with several entries should not be formatted in one line
    if ast.kind ==# 'Paragraph' && len(ast.value) != 1
        return false
    endif
    return ast.pos_to - ast.pos_from < g:smt2_formatter_short_length && !ast.contains_comment
enddef

def FormatOneLine(ast: parser.Ast): string
    if ast.kind ==# 'Atom'
        var token: scanner_ns.Token = ast.value
        return token.lexeme
    elseif ast.kind ==# 'SExpr'
        var formatted = []
        for expr in ast.value
            call formatted->add(expr->FormatOneLine())
        endfor
        return '(' .. formatted->join(' ') .. ')'
    elseif ast.kind ==# 'Paragraph'
        return ast.value[0]->FormatOneLine()
    endif
    throw 'Cannot format AST node: ' .. string(ast)
enddef

def Format(ast: parser.Ast, indent = 0): string
    const indent_str = repeat(g:smt2_formatter_indent_str, indent)

    if ast.kind ==# 'Atom'
        const token: scanner_ns.Token = ast.value
        return indent_str .. token.lexeme
    elseif ast.kind ==# 'SExpr'
        # Short expression -- avoid line breaks
        if ast->FitsOneLine()
            return indent_str .. ast->FormatOneLine()
        endif

        # Long expression -- break lines and indent subexpressions.
        # Don't break before first subexpression if it's an atom
        # Note: ast.value->empty() == false; otherwise it would fit in one line
        var formatted = []
        const exprs: list<parser.Ast> = ast.value
        if (exprs[0].kind ==# 'Atom')
            call formatted->add(exprs[0]->Format(0))
        else
            call formatted->add("\n" .. exprs[0]->Format(indent + 1))
        endif
        for child in exprs[1 :]
            call formatted->add(child->Format(indent + 1))
        endfor
        return indent_str .. "(" .. formatted->join("\n") .. ")"
    elseif ast.kind ==# 'Paragraph'
        var formatted = []
        for child in ast.value
            call formatted->add(child->Format())
        endfor
        return formatted->join("\n")
    elseif ast.kind ==# 'File'
        var formatted = []
        for child in ast.value
            call formatted->add(child->Format())
        endfor
        return formatted->join("\n\n")
    endif
    throw 'Cannot format AST node: ' .. string(ast)
enddef

# ------------------------------------------------------------------------------
# Auxiliary
# ------------------------------------------------------------------------------
def FormatInCurrentBuffer(ast: parser.Ast)
    const cursor = getpos('.')

    # Format lines and potential surrounding text on them
    const formatted_lines = split(Format(ast), '\n')
    const ast_coords = ast.CalcCoords()
    const ws_mask = " \n\r\t"
    const first_line_part_to_keep = getline(ast_coords[0].line)
        ->strcharpart(0, ast_coords[0].col - 2)
        ->trim(ws_mask, 2)
    const last_line_part_to_keep = getline(ast_coords[1].line)
        ->strcharpart(ast_coords[1].col - 1)
        ->trim(ws_mask, 1)

    # If section of AST has trailing whitespace until the file end, remove it
    cursor(ast_coords[1].line, ast_coords[1].col)
    if search('\m\C\S', 'W') == 0
        deletebufline('%', ast_coords[1].line + 1, line('$'))
    endif

    # Replace section of AST by formatted lines (w/o killing surrounding text)
    :silent deletebufline('%', ast_coords[0].line, ast_coords[1].line)
    if !empty(last_line_part_to_keep)
        last_line_part_to_keep->append(ast_coords[0].line - 1)
    endif
    formatted_lines->append(ast_coords[0].line - 1)
    if !empty(first_line_part_to_keep)
        first_line_part_to_keep->append(ast_coords[0].line - 1)
    endif

    # If section of AST has leading whitespace until the file start, remove it
    cursor(ast_coords[0].line, ast_coords[0].col)
    if search('\m\C\S', 'bW') == 0
        deletebufline('%', 1, ast_coords[0].line - 1)
    endif

    # Restore cursor position
    call setpos('.', cursor)
enddef

# ------------------------------------------------------------------------------
# Public functions
# ------------------------------------------------------------------------------
export def FormatCurrentParagraph()
    const ast = smt2#parser#ParseCurrentParagraph()
    FormatInCurrentBuffer(ast)
enddef

export def FormatOutermostSExpr()
    const ast = smt2#parser#ParseOutermostSExpr()
    FormatInCurrentBuffer(ast)
enddef

export def FormatFile()
    const ast = smt2#parser#ParseBuffer()
    FormatInCurrentBuffer(ast)
enddef
