local M = {}
local MiniTest = require('mini.test')
local expect, eq = MiniTest.expect, MiniTest.expect.equality

M.truthy = MiniTest.new_expectation(
    'truthy',
    function(x) return x end,
    function(x) return 'Object: ' .. vim.inspect(x) end
)

M.__index = M

function M:setup()
    local obj = setmetatable({}, self)
    obj.child = MiniTest.new_child_neovim()
    obj.test_set = MiniTest.new_set({
        hooks = {
            pre_case = obj.child.restart,
            post_once = obj.child.stop,
        },
    })
    obj.child.start({}, { nvim_executable = './lua/tests/nvim_wrapper.sh' })
    return obj
end

function M:toggle_snippets() self.child.cmd('TypstarToggleSnippets') end

function M:jump() self.child.cmd('lua require("luasnip").jump(1)') end

function M:jump_back() self.child.cmd('lua require("luasnip").jump(-1)') end

function M:add_cases(name, cases)
    self.test_set[name] = self.test_set[name] or MiniTest.new_set()
    for cname, case in pairs(cases) do
        self.test_set[name][cname] = case
    end
    return self.test_set
end

function M:eval_snip(input, math)
    if math then
        self.child.cmd('startinsert')
        self.child.type_keys('$$<ESC>')
    end
    self.child.bo.filetype = 'typst'
    self.child.cmd('startinsert')

    local skip_next = false
    for i = 1, #input do
        if skip_next then
            skip_next = false
            goto continue
        end

        local char = string.char(input:byte(i))
        if char == '\\' then
            local cmd = string.char(input:byte(i + 1))
            if cmd == 'j' then
                self:jump()
            elseif cmd == 'b' then
                self:jump_back()
            elseif cmd == 't' then
                self:toggle_snippets()
            end
            skip_next = true
        else
            pcall(self.child.type_keys, 3, char)
        end
        ::continue::
    end
    return table.concat(self.child.api.nvim_buf_get_lines(0, 0, -1, true), '\n')
end

function M:test_snip(input, want) eq(self:eval_snip(input, false), want) end

function M:test_snip_math(input, want) eq(self:eval_snip(input, true), '$' .. want .. '$') end

return M
