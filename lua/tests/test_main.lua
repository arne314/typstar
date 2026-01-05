MiniTest = require('mini.test')
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local child = MiniTest.new_child_neovim()
child.start({}, { nvim_executable = './lua/tests/nvim_wrapper.sh' })

local T = new_set({
    hooks = {
        pre_case = child.restart(),
        post_once = child.stop,
    },
})

T['jsregexp'] = function()
    local jsregexp_ok, _ = pcall(require, 'jsregexp')
    eq(jsregexp_ok, true)
end

return T
