local M = {}
local cfg = require('typstar.config').config.snippets
local luasnip = require('luasnip')
local events = require("luasnip.util.events")
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
    callback = function() last_keystroke_time = vim.uv.now() end,
})

M.in_math = function()
    local cursor = utils.get_cursor_pos()
    return utils.cursor_within_treesitter_query(ts_math_query, 0, 0, cursor)
        and not utils.cursor_within_treesitter_query(ts_string_query, 0, 0, cursor)
end
M.in_markup = function() return utils.cursor_within_treesitter_query(ts_markup_query, 1, 2) end
M.not_in_math = function() return not M.in_math() end
M.not_in_markup = function() return not M.in_markup() end
M.snippets_toggle = true

function M.snip(trigger, expand, insert, condition, priority, options)
    priority = priority or 1000
    options = vim.tbl_deep_extend('force', {
        maxTrigLength = nil,
        wordTrig = true,
        blacklist = {},
        prepend = nil,
        indentCaptureIdx = nil,
        callbacks = {
            pre = nil,
            post = nil
        }
    }, options or {})
    if options.prepend ~= nil or options.indentCaptureIdx ~= nil then
        expand, insert = M.blocktransform(expand, insert, options.prepend, options.indentCaptureIdx)
    end

    local callbacks = options.callbacks and {
        [-1] = {
            [events.pre_expand] = options.callbacks.pre,
            [events.leave] = options.callbacks.post
        },
    } or {}
    options = vim.tbl_deep_extend('keep', { callbacks = nil }, options or {})

    return luasnip.snippet(
        {
            trig = trigger,
            trigEngine = M.engine,
            trigEngineOpts = vim.tbl_deep_extend('keep', {
                condition = condition,
            }, options),
            wordTrig = false,
            priority = priority,
            snippetType = 'autosnippet',
        },
        fmta(expand, { unpack(insert) }),
        {
            condition = function() return M.snippets_toggle end,
            callbacks = callbacks
        }
    )
end

local alts_regex = '[\\[\\(](.*|.*)[\\)\\]]'

function M.engine(trigger, opts)
    local base_engine = lsengines.ecma(trigger, opts)

    -- determine possibly max/fixed length of trigger
    local max_length = opts.maxTrigLength
    local is_fixed_length = false
    if max_length == nil and alts_regex ~= '' and not trigger:match('[%+%*]') then
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
    return function(line_full, trig)
        if not M.snippets_toggle or not condition() then return nil end
        local first_idx = 1
        if max_length ~= nil then
            -- include additional char for wordtrig
            first_idx = #line_full - max_length
            if first_idx < 1 then
                if is_fixed_length and first_idx < 0 then
                    return nil
                else
                    first_idx = 1
                end
            end
        end
        if line_full:byte(first_idx) > 127 then first_idx = 1 end -- avoid splitting bytes within unicode characters
        local line = line_full:sub(first_idx)
        local whole, captures = base_engine(line, trig)
        if whole == nil then return nil end

        -- custom word trig
        local from = #line - #whole + 1
        local first_letter = line:sub(from - 1, from - 1)
        if opts.wordTrig and from ~= 1 and (first_letter:byte(1) > 127 or first_letter:match('[%w._]') ~= nil) then
            return nil
        end

        -- blacklist
        for _, w in ipairs(opts.blacklist) do
            if line_full:sub(- #w) == w then return nil end
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
            if type(alts_regex) == 'string' then alts_regex = jsregexp.compile_safe(alts_regex) end
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

        if cfg.add_undo_breakpoints then
            vim.api.nvim_create_autocmd('User', {
                pattern = 'LuasnipPreExpand',
                callback = function()
                    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<C-g>u', true, false, true), 'i', false)
                end,
            })
        end
    end
end

return M
