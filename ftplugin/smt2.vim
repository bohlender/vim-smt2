setlocal iskeyword+=-,:,#,',$
setlocal commentstring=;%s

" ------------------------------------------------------------------------------
" Mappings for solver functionality
" ------------------------------------------------------------------------------
nnoremap <silent> <buffer> <Plug>Smt2Run :call smt2#solver#Run()<cr>
if !hasmapto('<Plug>Smt2Run', 'n')
    nmap <silent> <localleader>r <Plug>Smt2Run
endif

nnoremap <silent> <buffer> <Plug>Smt2RunAndShowResult :call smt2#solver#RunAndShowResult()<cr>
if !hasmapto('<Plug>Smt2RunAndShowResult', 'n')
    nmap <unique> <silent> <localleader>R <Plug>Smt2RunAndShowResult
endif

nnoremap <silent> <Plug>Smt2PrintVersion :call smt2#solver#PrintVersion()<CR>
if !hasmapto('<Plug>Smt2PrintVersion', 'n')
    nmap <silent> <localleader>v <Plug>Smt2PrintVersion
endif

" ------------------------------------------------------------------------------
" Mappings for formatting functionality
" ------------------------------------------------------------------------------
nnoremap <silent> <buffer> <Plug>Smt2FormatOutermostSExpr :call smt2#formatter#FormatOutermostSExpr()<cr>
if !hasmapto('<Plug>Smt2FormatOutermostSExpr', 'n')
    nmap <silent> <localleader>f <Plug>Smt2FormatOutermostSExpr
endif

nnoremap <silent> <buffer> <Plug>Smt2FormalFile :call smt2#formatter#FormatFile()<cr>
if !hasmapto('<Plug>Smt2FormalFile', 'n')
    nmap <silent> <localleader>F <Plug>Smt2FormalFile
endif
