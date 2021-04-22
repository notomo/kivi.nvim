
function! kivi#is_parent() abort
    return luaeval('require("kivi.entrypoint.command").is_parent()')
endfunction
