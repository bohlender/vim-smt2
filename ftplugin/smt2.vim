setlocal iskeyword+=-,:,#,',$

" If no command for invoking the solver is specified in ~/.vimrc, default to
" looking for 'z3' or 'boolector' in $PATH
if !exists("g:smt2_solver_command")
    if executable("z3")
        let g:smt2_solver_command = "z3"
    elseif executable("boolector")
        let g:smt2_solver_command = "boolector"
    else
        echoerr "No SMT solver command set. Add 'let g:smt2_solver_command=...' to your ~/.vimrc"
    endif
endif

" If no command line switch for printing the solver's version is specified in
" ~/.vimrc, use '--version'
if !exists("g:smt2_solver_version_switch")
    let g:smt2_solver_version_switch = "--version"
endif

" Mappings
nnoremap <silent> <buffer> <localleader>r :call smt2#RunSolver()<cr>
nnoremap <silent> <buffer> <localleader>R :call smt2#RunSolverAndShowResult()<cr>
nnoremap <silent> <buffer> <localleader>v :call smt2#PrintSolverVersion()<cr>

" Comment String
setlocal commentstring=;%s
