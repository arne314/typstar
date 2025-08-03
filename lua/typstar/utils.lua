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

function M.get_treesitter_root(bufnr) return ts.get_parser(bufnr):parse()[1]:root() end

function M.treesitter_iter_matches(root, query, bufnr, start, stop)
    local result = {}
    local idx = 1
    for _, matches, _ in query:iter_matches(root, bufnr, start, stop) do
        if #matches then
            if type(matches[1]) == 'userdata' then -- nvim version < 0.11
                matches = { matches }
            end
            result[idx] = matches
            idx = idx + 1
        end
    end
    return result
end

function M.treesitter_match_start_end(match)
    local start_row, start_col, _, _ = match[1]:range()
    local _, _, end_row, end_col = match[#match]:range()
    return start_row, start_col, end_row, end_col
end

function M.cursor_within_treesitter_query(query, match_tolerance_l, match_tolerance_r, cursor)
    cursor = cursor or M.get_cursor_pos()
    match_tolerance_l = match_tolerance_l or 0
    match_tolerance_r = match_tolerance_r or 0
    local bufnr = vim.api.nvim_get_current_buf()
    local root = M.get_treesitter_root(bufnr)
    for _, match in ipairs(M.treesitter_iter_matches(root, query, bufnr, cursor[1], cursor[1] + 1)) do
        for _, nodes in pairs(match) do
            local start_row, start_col, end_row, end_col = M.treesitter_match_start_end(nodes)
            local matched = M.cursor_within_coords(
                cursor,
                start_row,
                end_row,
                start_col,
                end_col,
                match_tolerance_l,
                match_tolerance_r
            )
            if matched then return true end
        end
    end
    return false
end

function M.cursor_within_coords(cursor, start_row, end_row, start_col, end_col, match_tolerance_l, match_tolerance_r)
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
