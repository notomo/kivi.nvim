if exists('g:loaded_kivi')
    finish
endif
let g:loaded_kivi = 1

if get(g:, 'kivi_debug', v:false)
    command! -nargs=* -range=0 Kivi lua require("kivi/lib/module").cleanup(); require("kivi/entrypoint/command").start_by_excmd(<count>, {<line1>, <line2>}, {<f-args>})
    command! -nargs=* -range=0 KiviDo lua require("kivi/lib/module").cleanup(); require("kivi/entrypoint/command").execute(<count>, {<line1>, <line2>}, {<f-args>})
    augroup kivi
        autocmd!
        autocmd BufReadCmd kivi://* lua require("kivi/lib/module").cleanup(); require("kivi/entrypoint/command").read(tonumber(vim.fn.expand('<abuf>')))
    augroup END
else
    command! -nargs=* -range=0 Kivi lua require("kivi/entrypoint/command").start_by_excmd(<count>, {<line1>, <line2>}, {<f-args>})
    command! -nargs=* -range=0 KiviDo lua require("kivi/entrypoint/command").execute(<count>, {<line1>, <line2>}, {<f-args>})
    augroup kivi
        autocmd!
        autocmd BufReadCmd kivi://* lua require("kivi/entrypoint/command").read(tonumber(vim.fn.expand('<abuf>')))
    augroup END
endif
