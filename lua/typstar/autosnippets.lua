local M = require('typstar.engine') -- inherit all functions
local luasnip = require('luasnip')

function M.cap(i, transform_fn)
    local node = luasnip.function_node(function(_, snip)
        local result = snip.captures[i]
        if transform_fn then
            result = transform_fn(result)
        end
        return result
    end)
    return node
end

local compute_leading_white_spaces = function(snip, i)
    local capture = snip.captures[i] or ''
    return capture:match('^%s*') or ''
end

function M.leading_white_spaces(i)
    return luasnip.function_node(function(_, snip) return compute_leading_white_spaces(snip, i) end)
end

function M.visual(idx, default, line_prefix, indent_capture_idx)
    default = default or ''
    line_prefix = line_prefix or ''
    return luasnip.dynamic_node(idx, function(_, snip)
        local select_raw = snip.snippet.env.LS_SELECT_RAW
        if #select_raw > 0 then
            if line_prefix ~= '' then -- e.g. indentation
                for i, s in ipairs(select_raw) do
                    select_raw[i] = line_prefix .. s
                end
            end
            return luasnip.snippet_node(nil, luasnip.text_node(select_raw))
        else -- If LS_SELECT_RAW is empty, return an insert node
            local leading = ''
            if indent_capture_idx ~= nil then leading = compute_leading_white_spaces(snip, indent_capture_idx) end
            return luasnip.snippet_node(nil, {
                luasnip.text_node(leading .. line_prefix),
                luasnip.insert_node(1, default),
            })
        end
    end)
end

function M.ri(insert_node_id)
    return luasnip.function_node(function(args) return args[1][1] end, insert_node_id)
end

function M.start_snip(trigger, expand, insert, condition, priority, options)
    return M.snip('^(\\s*)' .. trigger, '<>' .. expand, { M.cap(1), unpack(insert) }, condition, priority, options)
end

-- transform the snippet expand by inserting indentation and/or a prefix after each newline
function M.blocktransform(expand, insert, prepend, indent_capture_idx)
    local indent = indent_capture_idx ~= nil
    if not indent and not prepend then return expand, insert end
    prepend = prepend or ''

    local modified_expand = expand
    local modified_insert = {}
    for i, v in pairs(insert) do
        modified_insert[i] = v
    end
    local offset = 0
    local last_pos = 0

    while true do
        local newline_pos = string.find(expand, '\n', last_pos + 1)
        if not newline_pos then break end

        -- prepend string
        local insert_pos = newline_pos + offset + 1
        local prefix = (indent and '<>' or '') .. prepend
        modified_expand = string.sub(modified_expand, 1, insert_pos - 1)
            .. prefix
            .. string.sub(modified_expand, insert_pos)
        offset = offset + #prefix

        -- indent node
        if indent then
            local expand_before = string.sub(modified_expand, 1, insert_pos + 1)
            local indent_pos = select(2, string.gsub(expand_before, '<>', ''))
            table.insert(modified_insert, indent_pos, M.leading_white_spaces(indent_capture_idx))
        end
        last_pos = newline_pos
    end
    return modified_expand, modified_insert
end

function M.start_snip_in_newl(trigger, expand, insert, condition, priority, options)
    local line = (not options or options.transform == nil) and M.cap(1)
        or M.cap(1, options.transform)
    return M.snip(
    -- '([^\\s]\\s+)' .. trigger, -- old trigger which does not capture whole line
        '(.*\\S)\\s+' .. trigger,
        '<>\n' .. expand,
        { line, unpack(insert) },
        condition,
        priority,
        vim.tbl_deep_extend('force', { indentCaptureIdx = 1  }, options or {})
    )
end

function M.list_snip(trigger, expand, insert, condition, priority, options)
    return M.snip(
        '(^\\s*(-|\\+|\\d+\\.)\\s+.*\\s+)' .. trigger,
        '<>' .. expand,
        { M.cap(1), unpack(insert) },
        condition,
        priority,
        vim.tbl_deep_extend('keep', { indentCaptureIdx = 1 }, options or {})
    )
end

return M
