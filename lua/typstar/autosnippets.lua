local M = {}
local cfg = require('typstar.config').config.snippets
local luasnip = require('luasnip')
local utils = require('typstar.utils')
local fmta = require('luasnip.extras.fmt').fmta
local lsengines = require('luasnip.nodes.util.trig_engines')
local ts = vim.treesitter

local exclude_triggers_set = {}
local last_keystroke_time = nil
local lexical_result_cache = {}
local ts_markup_query = ts.query.parse('typst', '(text) @markup')
local ts_math_query = ts.query.parse('typst', '(math) @math')
local ts_string_query = ts.query.parse('typst', '(string) @string')

utils.generate_bool_set(cfg.exclude, exclude_triggers_set)
vim.api.nvim_create_autocmd('TextChangedI', {
    callback = function() last_keystroke_time = vim.loop.now() end,
})

M.in_math = function()
    local cursor = utils.get_cursor_pos()
    return utils.cursor_within_treesitter_query(ts_math_query, 0, cursor)
        and not utils.cursor_within_treesitter_query(ts_string_query, 0, cursor)
end
M.in_markup = function() return utils.cursor_within_treesitter_query(ts_markup_query, 2) end
M.not_in_math = function() return not M.in_math() end
M.not_in_markup = function() return not M.in_markup() end
M.snippets_toggle = true

function M.cap(i)
    return luasnip.function_node(function(_, snip) return snip.captures[i] end)
end

function M.leading_white_spaces(i)
    -- isolate whitespaces of captured group
    return luasnip.function_node(function(_, snip)
        local capture = snip.captures[i] or '' -- Return capture or empty string if nil
        -- Extract only leading whitespace using pattern matching
        local whitespace = capture:match('^%s*') or ''
        return whitespace
    end)
end

function M.visual(idx, default)
    default = default or ''
    return luasnip.dynamic_node(idx, function(args, parent)
        if #parent.snippet.env.LS_SELECT_RAW > 0 then
            return luasnip.snippet_node(nil, luasnip.text_node(parent.snippet.env.LS_SELECT_RAW))
        else -- If LS_SELECT_RAW is empty, return an insert node
            return luasnip.snippet_node(nil, luasnip.insert_node(1, default))
        end
    end)
end

function M.ri(insert_node_id)
    return luasnip.function_node(function(args) return args[1][1] end, insert_node_id)
end

function M.snip(trigger, expand, insert, condition, priority, wordTrig, maxTrigLength)
    priority = priority or 1000
    if wordTrig == nil then wordTrig = true end
    return luasnip.snippet(
        {
            trig = trigger,
            trigEngine = M.engine,
            trigEngineOpts = { condition = condition, wordTrig = wordTrig, maxTrigLength = maxTrigLength },
            wordTrig = false,
            priority = priority,
            snippetType = 'autosnippet',
        },
        fmta(expand, { unpack(insert) }),
        {
            condition = function() return M.snippets_toggle end,
        }
    )
end

function M.start_snip(trigger, expand, insert, condition, priority)
    return M.snip('^(\\s*)' .. trigger, '<>' .. expand, { M.cap(1), unpack(insert) }, condition, priority)
end

function M.start_snip_in_newl(trigger, expand, insert, condition, priority)
    return M.snip(
        '([^\\s]\\s+)' .. trigger,
        '<>\n<>' .. expand,
        { M.cap(1), M.leading_white_spaces(1), unpack(insert) },
        condition,
        priority,
        false
    )
end

local alts_regex = '[\\[\\(](.*|.*)[\\)\\]]'

function M.engine(trigger, opts)
    local base_engine = lsengines.ecma(trigger, opts)

    -- determine possibly max/fixed length of trigger
    local max_length = opts.maxTrigLength
    local is_fixed_length = false
    if alts_regex ~= '' and not trigger:match('[%+%*]') then
        max_length = #trigger
            - utils.count_string(trigger, '\\')
            - utils.count_string(trigger, '%(')
            - utils.count_string(trigger, '%)')
            - utils.count_string(trigger, '%?')
        is_fixed_length = not trigger:match('[%+%*%?%[%]|]')

        local alts_match = alts_regex:match(trigger) -- find longest trigger in [...|...]
        if alts_match then
            for _, alts in ipairs(alts_match) do
                local max_alt_length = 1
                for alt in alts:gmatch('([^|]+)') do
                    local len
                    if alt:match('%[.*-.*%]') then -- [A-Za-z0-9] and similar
                        len = 2
                    else
                        len = #alt
                    end
                    max_alt_length = math.max(max_alt_length, len)
                end
                max_length = max_length - (#alts - max_alt_length)
            end
        else -- [^...] and similar
            max_length = max_length - utils.count_string(trigger, '%[') - utils.count_string(trigger, '%]')
        end
    end

    -- cache preanalysis results
    local condition = function()
        local cached = lexical_result_cache[opts.condition]
        if cached ~= nil and cached[1] == last_keystroke_time then return cached[2] end
        local result = opts.condition()
        lexical_result_cache[opts.condition] = { last_keystroke_time, result }
        return result
    end

    -- matching
    return function(line, trig)
        if not M.snippets_toggle or not condition() then return nil end
        if max_length ~= nil then
            local first_idx = #line - max_length -- include additional char for wordtrig
            if first_idx < 0 then
                if is_fixed_length then
                    return nil
                else
                    first_idx = 1
                end
            end
            if first_idx > 0 then
                if string.byte(line, first_idx) > 127 then return nil end
            end
            line = line:sub(first_idx)
        end
        local whole, captures = base_engine(line, trig)
        if whole == nil then return nil end

        -- custom word trig
        local from = #line - #whole + 1
        if opts.wordTrig and from ~= 1 and string.match(string.sub(line, from - 1, from - 1), '[%w.]') ~= nil then
            return nil
        end
        return whole, captures
    end
end

function M.toggle_autosnippets()
    M.snippets_toggle = not M.snippets_toggle
    print(string.format('%sabled typstar autosnippets', M.snippets_toggle and 'En' or 'Dis'))
end

function M.setup()
    if cfg.enable then
        local jsregexp_ok, jsregexp = pcall(require, 'luasnip-jsregexp')
        if not jsregexp_ok then
            jsregexp_ok, jsregexp = pcall(require, 'jsregexp')
        end
        if jsregexp_ok then
            alts_regex = jsregexp.compile_safe(alts_regex)
        else
            alts_regex = ''
            vim.notify("WARNING: Most snippets won't work as jsregexp is not installed", vim.log.levels.WARN)
        end
        local autosnippets = {}
        for _, file in ipairs(cfg.modules) do
            for _, sn in ipairs(require(('typstar.snippets.%s'):format(file))) do
                local exclude
                local is_start = sn.trigger:match('^%^%(\\s%*%)')
                if is_start then
                    exclude = exclude_triggers_set[sn.trigger:sub(7)]
                else
                    exclude = exclude_triggers_set[sn.trigger]
                end
                if not exclude then table.insert(autosnippets, sn) end
            end
        end
        luasnip.add_snippets('typst', autosnippets)
    end
end

return M
