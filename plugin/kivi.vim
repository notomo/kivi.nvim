if exists('g:loaded_kivi')
    finish
endif
let g:loaded_kivi = 1

augroup kivi
    autocmd!
    autocmd BufReadCmd kivi://* lua require("kivi.command").Command.new("read", tonumber(vim.fn.expand('<abuf>')))
augroup END

augroup kivi_mapping
    autocmd!
    autocmd FileType kivi-* call s:mapping()
augroup END

function! s:mapping() abort
    nnoremap <silent> <buffer> <expr> j line('.') == line('$') ? 'gg' : 'j'
    nnoremap <silent> <buffer> <expr> k line('.') == 1 ? 'G' : 'k'
    nnoremap <buffer> h <Cmd>lua require("kivi").execute("parent")<CR>
    nnoremap <buffer> l <Cmd>lua require("kivi").execute("child")<CR>
    nnoremap <nowait> <buffer> q <Cmd>quit<CR>
endfunction
