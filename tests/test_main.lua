MiniTest = require('mini.test')
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local T = new_set({
    hooks = {
        pre_case = function() child.restart({ '-u', 'tests/init.lua' }) end,
        post_once = child.stop,
    },
})

T['jsregexp'] = function()
    local jsregexp_ok, _ = pcall(require, 'jsregexp')
    eq(jsregexp_ok, true)
end

return T
