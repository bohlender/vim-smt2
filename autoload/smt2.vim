" Invokes Z3 on current file
function! smt2#RunZ3()
    silent !clear
    execute "!" . g:smt2_z3_command . " " . bufname("%")
endfunction

" Puts Z3's output in new split (replaces old split)
function! smt2#RunZ3AndShowResult()
    let output = system(g:smt2_z3_command . " " . bufname("%") . " 2>&1")

    " Create split (or reuse existent)
    if exists("s:outputbufnr") && bufwinnr(s:outputbufnr) > 0
        execute bufwinnr(s:outputbufnr) . 'wincmd w'
    else
        silent! vnew
        let s:outputbufnr=bufnr('%')
    endif
   
    " Clear & (re-)fill contents
    silent! normal! ggdG
    setlocal filetype=smt2 buftype=nofile nobuflisted noswapfile
    call append(0, split(output, '\v\n'))
    normal! gg
endfunction
