local ts = vim.treesitter
local ls = require('luasnip')
local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet_node
local t = ls.text_node

local utils = require('typstar.utils')
local helper = require('typstar.autosnippets')
local math = helper.in_math
local snip = helper.snip

local snippets = {}
local operations = {                            -- first boolean: existing brackets should be kept; second boolean: brackets should be added
    { 'vi',  '1/',         '',  true,  false },
    { 'bb',  '(',          ')', true,  false }, -- add round brackets
    { 'sq',  '[',          ']', true,  false }, -- add square brackets
    { 'st',  '{',          '}', true,  false }, -- add curly brackets 
    { 'bB',  '(',          ')', false, false }, -- replace with round brackets
    { 'sQ',  '[',          ']', false, false }, -- replace with square brackets
    { 'BB',  '',           '',  false, false }, -- remove brackets
    { 'ss',  '"',          '"', false, false },
    { 'abs', 'abs',        '',  true,  true },
    { 'ul',  'underline',  '',  true,  true },
    { 'ol',  'overline',   '',  true,  true },
    { 'ub',  'underbrace', '',  true,  true },
    { 'ob',  'overbrace',  '',  true,  true },
    { 'ht',  'hat',        '',  true,  true },
    { 'br',  'macron',     '',  true,  true },
    { 'dt',  'dot',        '',  true,  true },
    { 'ci',  'circle',     '',  true,  true },
    { 'td',  'tilde',      '',  true,  true },
    { 'nr',  'norm',       '',  true,  true },
    { 'vv',  'vec',        '',  true,  true },
    { 'rt',  'sqrt',       '',  true,  true },
    { 'flo', 'floor',      '',  true,  true },
    { 'cei', 'ceil',       '',  true,  true },
}

local ts_wrap_query = ts.query.parse('typst', '[(call) (ident) (letter) (number)] @wrap')
local ts_wrapnobrackets_query = ts.query.parse('typst', '(group) @wrapnobrackets')

local process_ts_query = function(bufnr, cursor, query, root, insert1, insert2, cut_offset)
    for _, match, _ in query:iter_matches(root, bufnr, cursor[1], cursor[1] + 1) do
        if match then
            local start_row, start_col, end_row, end_col = utils.treesitter_match_start_end(match)
            if end_row == cursor[1] and end_col == cursor[2] then
                vim.schedule(function() -- to not interfere with luasnip
                    local cursor_offset = 0
                    local old_len1, new_len1 = utils.insert_text(
                        bufnr, start_row, start_col, insert1, 0, cut_offset)
                    if start_row == cursor[1] then
                        cursor_offset = cursor_offset + (new_len1 - old_len1)
                    end
                    local old_len2, new_len2 = utils.insert_text(
                        bufnr, end_row, cursor[2] + cursor_offset, insert2, cut_offset, 0)
                    if end_row == cursor[1] then
                        cursor_offset = cursor_offset + (new_len2 - old_len2)
                    end
                    vim.api.nvim_win_set_cursor(0, { cursor[1] + 1, cursor[2] + cursor_offset })
                end)
                return true
            end
        end
    end
    return false
end

local smart_wrap = function(args, parent, old_state, expand)
    local bufnr = vim.api.nvim_get_current_buf()
    local cursor = utils.get_cursor_pos()
    local root = utils.get_treesitter_root(bufnr)

    if process_ts_query(bufnr, cursor, ts_wrapnobrackets_query, root, expand[2], expand[3], expand[4] and 0 or 1) then
        return s(nil, t())
    end

    local expand1 = expand[5] and expand[2] .. '(' or expand[2]
    local expand2 = expand[5] and expand[3] .. ')' or expand[3]
    if process_ts_query(bufnr, cursor, ts_wrap_query, root, expand1, expand2) then
        return s(nil, t())
    end
    if #parent.env.LS_SELECT_RAW > 0 then
        return s(nil, t(expand1 .. table.concat(parent.env.LS_SELECT_RAW) .. expand2))
    end
    return s(nil, { t(expand1), i(1, '1+1'), t(expand2) })
end

for _, val in pairs(operations) do
    table.insert(snippets, snip(val[1], '<>', { d(1, smart_wrap, {}, { user_args = { val } }) }, math, 1000, false))
end

return {
    unpack(snippets)
}
