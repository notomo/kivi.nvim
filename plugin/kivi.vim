if exists('g:loaded_kivi')
    finish
endif
let g:loaded_kivi = 1

command! -nargs=* -range=0 Kivi lua require("kivi.entrypoint.command").start_by_excmd(<count>, {<line1>, <line2>}, {<f-args>})
command! -nargs=* -range=0 KiviDo lua require("kivi.entrypoint.command").execute(<count>, {<line1>, <line2>}, {<f-args>})
augroup kivi
    autocmd!
    autocmd BufReadCmd kivi://* lua require("kivi.entrypoint.command").read(tonumber(vim.fn.expand('<abuf>')))
augroup END

augroup kivi_mapping
    autocmd!
    autocmd FileType kivi-* call s:mapping()
augroup END

function! s:mapping() abort
    nnoremap <silent> <buffer> <expr> j line('.') == line('$') ? 'gg' : 'j'
    nnoremap <silent> <buffer> <expr> k line('.') == 1 ? 'G' : 'k'
    nnoremap <buffer> h <Cmd>KiviDo parent<CR>
    nnoremap <buffer> l <Cmd>KiviDo child<CR>
    nnoremap <nowait> <buffer> q <Cmd>quit<CR>
endfunction
