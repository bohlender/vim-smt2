setlocal iskeyword+=-,:,#,',$
setlocal commentstring=;%s

" Mappings for solver functionality
nnoremap <silent> <buffer> <localleader>r :call smt2#solver#Run()<cr>
nnoremap <silent> <buffer> <localleader>R :call smt2#solver#RunAndShowResult()<cr>
nnoremap <silent> <buffer> <localleader>v :call smt2#solver#PrintVersion()<cr>

" Mappings for formatting functionality
let formatting_supported = (v:version >= 802) || (v:version == 802 && has("patch2725"))
if formatting_supported
    nnoremap <silent> <buffer> <localleader>f :call smt2#formatter#FormatCurrentParagraph()<cr>
    nnoremap <silent> <buffer> <localleader>F :call smt2#formatter#FormatAllParagraphs()<cr>

    " Use these to benchmark parsing
    "nnoremap <silent> <buffer> <localleader>f :call smt2#parser#ParseCurrentParagraph()<cr>
    "nnoremap <silent> <buffer> <localleader>F :call smt2#parser#ParseAllParagraphs()<cr>
else
    let errmsg = "Vim >= 8.2.2725 required for auto-formatting"
    nnoremap <silent> <buffer> <localleader>f :echoerr errmsg<cr>
    nnoremap <silent> <buffer> <localleader>F :echoerr errmsg<cr>
endif
