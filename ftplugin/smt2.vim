setlocal iskeyword+=-,:,#,',$

" If no command for invoking the Z3 solver is specified in ~/.vimrc,
" assume 'z3' to be in $PATH
if !exists("g:smt2_z3_command")
    let g:smt2_z3_command = "z3"
endif

" Mappings
nnoremap <silent> <buffer> <localleader>r :call smt2#RunZ3()<cr>
nnoremap <silent> <buffer> <localleader>R :call smt2#RunZ3AndShowResult()<cr>
nnoremap <silent> <buffer> <localleader>v :call smt2#PrintZ3Version()<cr>
