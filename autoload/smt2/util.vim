vim9script

# Returns true if successful, i.e. on move to '(' of outermost SExpr
def smt2#util#MoveToOutermostSExpr(): bool
    var cur_pos = getpos('.')
    while true
        silent! normal! [(
        const new_pos = getpos('.')
        if cur_pos == new_pos
            break
        else
            cur_pos = new_pos
        endif
    endwhile

    const cur_char = getline('.')[charcol('.') - 1]
    return cur_char == '('
enddef
