setlocal iskeyword+=-,:,#,',$
setlocal commentstring=;%s

" Mappings for solver functionality
nnoremap <silent> <buffer> <localleader>r :call smt2#solver#Run()<cr>
nnoremap <silent> <buffer> <localleader>R :call smt2#solver#RunAndShowResult()<cr>
nnoremap <silent> <buffer> <localleader>v :call smt2#solver#PrintVersion()<cr>

" Mappings for formatting functionality
nnoremap <silent> <buffer> <localleader>f :call smt2#formatter#FormatOutermostSExpr()<cr>
nnoremap <silent> <buffer> <localleader>F :call smt2#formatter#FormatFile()<cr>
