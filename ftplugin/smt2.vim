setlocal iskeyword+=-,:,#,',$

" If no command for invoking the solver is specified in ~/.vimrc,
" assume 'boolector' to be in $PATH
if !exists("g:smt2_solver_command")
    let g:smt2_solver_command = "boolector"
endif

" If no command line switch for printing the solver's version is specified in
" ~/.vimrc, use '--version'
if !exists("g:smt2_solver_version")
    let g:smt2_solver_version = "--version"
endif

" Mappings
nnoremap <silent> <buffer> <localleader>r :call smt2#RunSolver()<cr>
nnoremap <silent> <buffer> <localleader>R :call smt2#RunSolverAndShowResult()<cr>
nnoremap <silent> <buffer> <localleader>v :call smt2#PrintSolverVersion()<cr>
