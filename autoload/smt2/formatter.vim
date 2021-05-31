vim9script

# TODO: Refer to token kind by name, e.g. token_comment instead of 8

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
# Format status
# ------------------------------------------------------------------------------
def Fail(): dict<any>
    return {success: false}
enddef

def Success(str: string): dict<any>
    return {success: true, str: str}
enddef

# ------------------------------------------------------------------------------
# Formatter
# ------------------------------------------------------------------------------
def FitsOneLine(ast: dict<any>): bool
    # A paragraph with several entries should not be formatted in one line
    if ast.kind ==# 'Paragraph' && len(ast.value) != 1
        return false
    endif
    return ast.pos_to - ast.pos_from < g:smt2_formatter_short_length && !ast.contains_comment
enddef

def FormatOneLine(ast: dict<any>): string
    # TODO: Assert FitsOneLine
    
    if ast.kind ==# 'Atom'
        return ast.value.lexeme
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
    return '' # Unreachable
enddef

def Format(ast: dict<any>, indent = 0): string
    const indent_str = repeat(g:smt2_formatter_indent_str, indent)

    if ast.kind ==# 'Atom'
        return indent_str .. ast.value.lexeme
    elseif ast.kind ==# 'SExpr'
        # Short expression -- avoid line breaks
        if ast->FitsOneLine()
            return indent_str .. ast->FormatOneLine()
        endif

        # Long expression -- break lines and indent subexpressions.
        # Don't break before first subexpression if it's an atom
        # Note: ast.value->empty() == false; otherwise it would fit in one line
        var formatted = []
        if (ast.value[0].kind ==# 'Atom')
            call formatted->add(ast.value[0]->Format(0))
        else
            call formatted->add("\n" .. ast.value[0]->Format(indent + 1))
        endif
        for child in ast.value[1 :]
            call formatted->add(child->Format(indent + 1))
        endfor
        return indent_str .. "(" .. formatted->join("\n") .. ")"
    elseif ast.kind ==# 'Paragraph'
        var formatted = []
        for child in ast.value
            call formatted->add(child->Format())
        endfor
        return formatted->join("\n")
    endif
    throw 'Cannot format AST node: ' .. string(ast)
    return '' # Unreachable
enddef

# ------------------------------------------------------------------------------
# Public functions
# ------------------------------------------------------------------------------
def smt2#formatter#FormatCurrentParagraph()
    const cursor = getpos('.')
    const t_start = reltime()
    const ast = smt2#parser#ParseCurrentParagraph()
    echo printf('Scanning & parsing took %s', reltimestr(reltime(t_start)))

    # Identify on which end of the buffer we are (to fix newlines later)
    silent! normal! {
    const is_first_paragraph = line('.') == 1
    silent! normal! }
    const is_last_paragraph = line('.') == line('$')

    # Replace paragraph by formatted lines
    const fmt_start = reltime()
    const lines = split(Format(ast), '\n')
    echo printf('Formatting took %s', reltimestr(reltime(fmt_start)))
    # amebsa 1,55 + 0.285
    # append_fs_unsafe.c 20.7 + 13.7
    silent! normal! {d}
    if is_last_paragraph
        call append('.', [''] + lines)
    else
        call append('.', lines + [''])
    endif

    # Remove potentially introduced first empty line
    if is_first_paragraph | silent! :1delete | endif

    # Restore cursor position
    call setpos('.', cursor)
enddef

def smt2#formatter#FormatAllParagraphs()
    const cursor = getpos('.')
    const asts = smt2#parser#ParseAllParagraphs()

    # Clear buffer & insert formatted paragraphs
    silent! :1,$delete
    for ast in asts
        const lines = split(Format(ast), '\n') + ['']
        call append('$', lines)
    endfor

    # Remove first & trailing empty lines
    silent! :1delete
    silent! :$delete

    # Restore cursor position
    call setpos('.', cursor)
enddef
