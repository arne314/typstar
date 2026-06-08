-- TODO: Bug with norm ?
--
--
-- & norm(a) \
--  = &
-- nor &m(a) \
-- <==>  &
--
--
local helper = require('typstar.autosnippets')
local tp = require('typstar.autosnippets')
local ls = require("luasnip")
local math = tp.in_math
local i = ls.insert_node
local ops1 = { "<==>", "==>", "<==", "and", "or" }
local ops2 = { ">=", "<=", "=" }
local ops = { "&" }
for _, op in ipairs(ops1) do table.insert(ops, op) end
for _, op in ipairs(ops2) do table.insert(ops, op) end


-- returns the node that should be aligned relative to from the current cursor
local function get_root_node()
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    -- tresitter is 0 indexed, lua not.
    cursor_row = cursor_row - 1
    local node = vim.treesitter.get_node({ bufnr = 0, pos = { cursor_row, cursor_col } })

    -- going up recursively
    while node do
        local type = node:type()
        if type == "math" then
            return node
        end

        -- the only case I've seen where alignment is supported within a TS-group
        -- is if it's a subscript group. This is the way to check if it's a subscript
        -- group.
        if type == "group" then
            local parent = node:parent()
            if parent then
                local sub_nodes = parent:field("sub")
                for _, sub in ipairs(sub_nodes) do
                    if sub == node then
                        return node
                    end
                end
            end
        elseif type == "call" then
            return node
        end

        -- TODO: other TS-types where internal alignment in math) is supported?

        node = node:parent()
    end
    return nil
end


-- requires a complete list of operators
local function max_match_from_ops(txt, ops, sorted_ops)
    if not sorted_ops then
        sorted_ops = {}
        if ops then
            for _, v in ipairs(ops) do table.insert(sorted_ops, v) end
            table.sort(sorted_ops, function(a, b) return #a > #b end)
        end
    end
    local results = {}
    local matched_mask = {}
    for j = 1, #txt do matched_mask[j] = false end
    for _, op in ipairs(sorted_ops) do
        local start_search = 1
        while true do
            local idx = txt:find(op, start_search, true)
            if not idx then break end

            local already_matched = false
            for pos = idx, idx + #op - 1 do
                if matched_mask[pos] then
                    already_matched = true
                    break
                end
            end

            if not already_matched then
                table.insert(results, { op, (idx - 1) })
                -- Claim characters to prevent shorter operators from matching same spot.
                for pos = idx, idx + #op - 1 do
                    matched_mask[pos] = true
                end
            end
            start_search = idx + 1
        end
    end
    return results
end


local function collect_ops_between_last_breaks(ops)
    -- SETUP VARS
    local bufnr = vim.api.nvim_get_current_buf()
    local parser = vim.treesitter.get_parser(bufnr)
    parser:parse()
    local cursor_row, cursor_col = unpack(vim.api.nvim_win_get_cursor(0))
    cursor_row = cursor_row - 1
    local math_node = get_root_node()
    if not math_node then return { results = {}, start_boundary = nil, end_boundary = nil, container = nil } end

    -- FIND LINE DELIMITERS ABSOLUTE POSITIONS
    -- using in-order tree traversal
    local last1, last2 = nil, nil
    local function walk(n)
        -- get a list of children
        local children = {}
        local count = n:child_count()
        for i = 0, count - 1 do
            table.insert(children, n:child(i))
        end

        -- open a walk branch for each of the children
        for _, child in ipairs(children) do
            local sr, sc, er, ec = child:range()
            local ctype = child:type()

            -- purge branch when the object passed the cursor
            if sr > cursor_row or (sr == cursor_row and sc > cursor_col) then
                return true
            end

            if ctype == "linebreak" then
                last2 = last1
                last1 = child
            end

            -- IMPORTANT STEP: Never recurse into subgroups!
            if ctype ~= "group" and ctype ~= "call" and ctype ~= "apply" and child:child_count() > 0 then
                local stop = walk(child)
                if stop then return true end
            end
        end
        return false
    end
    walk(math_node)

    if not last1 then
        return { results = {}, start_boundary = nil, end_boundary = nil, container = math_node }
    end
    if not last2 then last2 = math_node end

    -- 'a' (start) and 'b' (end) are the segment boundaries we found in the walk.
    local a_sr, a_sc = last2:range()
    local b_sr, b_sc = last1:range()

    -- Sort operators by length descending for maximal matching
    local sorted_ops = {}
    for _, v in ipairs(ops) do table.insert(sorted_ops, v) end
    table.sort(sorted_ops, function(a, b) return #a > #b end)

    local results = {}

    local function inspect(n)
        -- in-order tree search searching for symbols which are in the appropriate
        -- position.
        local count = n:child_count()
        for i = 0, count - 1 do
            local child = n:child(i)
            local sr, sc, er, ec = child:range()
            local ctype = child:type()

            -- if the currently to evaluate child is ahead of the cursor
            -- then any following children will be by tree-sitter ordering
            -- ahead of the cursor. Therefore kill the branch. (and thereby
            -- stop the search)
            if sr > b_sr or (sr == b_sr and sc >= b_sc) then
                return
            end
            -- parents carry start and end positions and if a parent doesn't
            -- even extend into the area, skip the recursion
            if er < a_sr or (er == a_sr and ec <= a_sc) then
                goto continue
            end

            -- if the branch element is a group, skip the recursion.
            if ctype == "group" or ctype == "call" or ctype == "apply" then
                goto continue
            end

            -- only bother to check symbol / element nodes.
            if child:child_count() == 0 then
                local txt = vim.treesitter.get_node_text(child, bufnr)

                local matches = max_match_from_ops(txt, nil, sorted_ops)
                for _, match in ipairs(matches) do
                    table.insert(results, { match[1], sr, sc + match[2] })
                end
            else
                inspect(child)
            end

            ::continue::
        end
    end

    inspect(math_node)

    return { results = results, start_boundary = last2, end_boundary = last1, container = math_node }
end

return {
    helper.snip('(\\S)\\s+ali', '<> \\\n <> & <>', { helper.cap(1), i(1, "="), tp.visual(2) }, math, nil, {
        wordTrig = false,
        callbacks = {
            [1] =
            {
                post = function(snippet)
                    local root = snippet.parent
                    local first_node = root.insert_nodes and root.insert_nodes[1]
                    local scan_result = collect_ops_between_last_breaks(ops)
                    local ops_in_segment = scan_result.results
                    local start_bound = scan_result.start_boundary

                    -- If an ampersand already exists in this segment, we don't need to add another.
                    local has_amp = false
                    for _, a in ipairs(ops_in_segment) do
                        if a[1] == "&" then
                            has_amp = true
                            break
                        end
                    end

                    if has_amp then return end

                    -- Determine alignment target based on the snippet's first input value.
                    local first_val = first_node:get_text()[1]
                    local op_match = max_match_from_ops(first_val, ops)
                    if op_match and op_match[1] then
                        first_val = op_match[1][1]
                    end
                    local target = nil

                    local function is_in(val, list)
                        for _, v in ipairs(list) do
                            if v == val then return true end
                        end
                        return false
                    end

                    -- Alignment Strategy:
                    if is_in(first_val, ops1) then
                        -- For CHAINS (ops1), we align to the FIRST operator of that type.
                        for _, a in ipairs(ops_in_segment) do
                            if is_in(a[1], ops1) then
                                target = a
                                break
                            end
                        end
                    else
                        -- For INEQUALITIES (ops2) or defaults, we align to the LAST operator.
                        for i = #ops_in_segment, 1, -1 do
                            local a = ops_in_segment[i]
                            if is_in(a[1], ops2) then
                                target = a
                                break
                            end
                        end
                    end

                    local row, column, line, outline

                    if target then
                        -- We found an operator to align with.
                        row = target[2]
                        column = target[3] + #target[1] -- Place ampersand AFTER the operator.
                        line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1]
                        outline = line:sub(1, column) .. " &" .. line:sub(column + 1)
                    elseif start_bound then
                        -- Fallback: No operators found. Align to the first symbol in the segment.
                        local sr, sc, er, ec = start_bound:range()
                        ---@type TSNode
                        local end_bound = scan_result.end_boundary
                        local br, bc = end_bound:range()

                        -- Determine the row/col where the actual mathematical content starts.
                        -- If bounded by the container itself (math or group), skip the header char (e.g. '$' or '(').
                        -- If bounded by a linebreak, skip the '\'.
                        local is_container = (start_bound == scan_result.container)
                        local start_row = is_container and sr or er
                        local start_col = is_container and sc + 1 or ec

                        for r = start_row, br do
                            local l = vim.api.nvim_buf_get_lines(0, r, r + 1, false)[1]
                            if l then
                                -- Skip the boundary itself if we are on its line.
                                local search_from = (r == start_row) and start_col + 1 or 1
                                local sub = l:sub(search_from)
                                local first_char_rel = sub:find("%S") -- Find first non-whitespace character.
                                if first_char_rel then
                                    row = r
                                    column = search_from + first_char_rel - 1
                                    line = l
                                    -- Prepend '& ' before the first symbol.
                                    outline = l:sub(1, column - 1) .. "& " .. l:sub(column)
                                    break
                                end
                            end
                        end
                    end

                    -- Final Buffer Modification
                    if outline and row then
                        vim.defer_fn(function()
                            vim.api.nvim_buf_set_lines(0, row, row + 1, false, { outline })
                        end, 1)
                    end
                end
            }

        }
    })
}
