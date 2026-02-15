local M = {}
local MiniTest = require('mini.test')

M.eq = MiniTest.expect.equality
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

-- overwrite the child buffer and place the cursor at `\\C`
function M:set_buffer(text)
    local cursor_line = 0
    local cursor_col = 0
    local cursor_pos = text:find('\\C', 1, true)
    if cursor_pos then
        local before = text:sub(1, cursor_pos - 1)
        local lines_before = vim.split(before, '\n', { plain = true })
        cursor_line = #lines_before - 1
        cursor_col = #lines_before[#lines_before]
        text = text:sub(1, cursor_pos - 1) .. text:sub(cursor_pos + 2)
    end
    local lines = vim.split(text, '\n', { plain = true })
    self.child.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    self.child.api.nvim_win_set_cursor(0, { cursor_line + 1, cursor_col })
end

-- evaluate a snippet by typing it out, `\\j` and `\\b` jump and `\\t` toggles all snippets
function M:eval_snip(input, mode)
    if mode == 'math' then
        self.child.cmd('startinsert')
        self.child.type_keys('$$<ESC>')
    elseif mode == 'code' then
        self.child.cmd('startinsert')
        self.child.type_keys('#{}<ESC>')
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

function M:test_snip(input, want)
    local buf = self:eval_snip(input, 'markup')
    M.eq(buf, want or input)
end

function M:test_snip_math(input, want)
    local buf = self:eval_snip(input, 'math')
    M.eq(buf, '$' .. (want or input) .. '$')
end

function M:test_snip_code(input, want)
    local buf = self:eval_snip(input, 'code')
    M.eq(buf, '#{' .. (want or input) .. '}')
end

return M
