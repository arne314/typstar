local M = {}
local ts = vim.treesitter

function M.get_cursor_pos()
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    cursor_row = cursor_row - 1
    return { cursor_row, cursor_col }
end

function M.insert_text(bufnr, row, col, snip, begin_offset, end_offset)
    begin_offset = begin_offset or 0
    end_offset = end_offset or 0
    local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, true)[1]
    local old_len = #line
    line = line:sub(1, col - begin_offset) .. snip .. line:sub(col + 1 + end_offset, #line)
    vim.api.nvim_buf_set_lines(bufnr, row, row + 1, false, { line })
    return old_len, #line
end

function M.insert_text_block(snip)
    local line_num = M.get_cursor_pos()[1] + 1
    local lines = {}
    for line in snip:gmatch('[^\r\n]+') do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), line_num, line_num, false, lines)
end

function M.run_shell_command(cmd, show_output, extra_handler, opts)
    extra_handler = extra_handler or function(msg) end
    opts = opts or { on_exit = function() end }
    local handle_output = function(data, err)
        local msg = table.concat(data, '\n')
        if not string.match(msg, '^%s*$') then
            extra_handler(msg)
            local level = err and vim.log.levels.ERROR or vim.log.levels.INFO
            vim.notify(msg, level)
        end
    end
    if show_output then
        return vim.fn.jobstart(
            cmd,
            vim.tbl_deep_extend('force', {
                on_stdout = function(_, data, _) handle_output(data, false) end,
                on_stderr = function(_, data, _) handle_output(data, true) end,
                stdout_buffered = false,
                stderr_buffered = true,
            }, opts)
        )
    else
        return vim.fn.jobstart(cmd, opts)
    end
end

function M.count_string(str, tocount)
    local _, count = str:gsub(tocount, '')
    return count
end

function M.char_to_hex(c) return string.format('%%%02X', string.byte(c)) end

function M.urlencode(url)
    if url == nil then return '' end
    url = string.gsub(url, '\n', '\r\n')
    url = string.gsub(url, '([^%w _%%%-%.~])', M.char_to_hex)
    url = string.gsub(url, ' ', '%%20')
    return url
end

function M.generate_bool_set(arr, target)
    for _, val in ipairs(arr) do
        target[val] = true
    end
end

function M.get_treesitter_root(bufnr) return ts.get_parser(bufnr or vim.api.nvim_get_current_buf()):parse()[1]:root() end

function M.cursor_within_treesitter_query(root, query, cursor, match_tolerance_l, match_tolerance_r)
    cursor = cursor or M.get_cursor_pos()
    match_tolerance_l = match_tolerance_l or 0
    match_tolerance_r = match_tolerance_r or 0
    local bufnr = vim.api.nvim_get_current_buf()

    for _, node, _, _ in query:iter_captures(root, bufnr, cursor[1], cursor[1] + 1) do
        local start_row, start_col, end_row, end_col = node:range()
        local matched =
            M.cursor_within_coords(cursor, start_row, start_col, end_row, end_col, match_tolerance_l, match_tolerance_r)
        if matched then return true end
    end
    return false
end

function M.cursor_within_coords(cursor, start_row, start_col, end_row, end_col, match_tolerance_l, match_tolerance_r)
    if start_row <= cursor[1] and end_row >= cursor[1] then
        if start_row == cursor[1] and start_col - match_tolerance_l >= cursor[2] then
            return false
        elseif end_row == cursor[1] and end_col + match_tolerance_r <= cursor[2] then
            return false
        end
        return true
    end
    return false
end

return M
