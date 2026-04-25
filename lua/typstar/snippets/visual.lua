local ls = require('luasnip')
local ts_postfix = require('luasnip.extras.treesitter_postfix').treesitter_postfix
local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet_node
local t = ls.text_node

local helper = require('typstar.autosnippets')
local utils = require('typstar.utils')
local cfg = require('typstar.config').config.snippets
local math = helper.in_math
local snip = helper.snip

local snippets = {}
local visual_disable = {}
local visual_disable_normal = {}
local visual_disable_postfix = {}
utils.generate_bool_set(cfg.visual_disable, visual_disable)
utils.generate_bool_set(cfg.visual_disable_normal, visual_disable_normal)
utils.generate_bool_set(cfg.visual_disable_postfix, visual_disable_postfix)

local operations = { -- first boolean: existing brackets should be kept; second boolean: brackets should be added
    { 'vi', '1/', '', true, false },
    { 'bb', '(', ')', true, false }, -- add round brackets
    { 'sq', '[', ']', true, false }, -- add square brackets
    { 'st', '{', '}', true, false }, -- add curly brackets
    { 'bB', '(', ')', false, false }, -- replace with round brackets
    { 'sQ', '[', ']', false, false }, -- replace with square brackets
    { 'BB', '', '', false, false }, -- remove brackets
    { 'ss', '"', '"', false, false },
    { 'chv', 'lr(chevron.l ', ' chevron.r)', false, false },
    { 'abs', 'abs', '', true, true },
    { 'ul', 'underline', '', true, true },
    { 'ol', 'overline', '', true, true },
    { 'ub', 'underbrace', '', true, true },
    { 'ob', 'overbrace', '', true, true },
    { 'ht', 'hat', '', true, true },
    { 'br', 'macron', '', true, true },
    { 'dt', 'dot', '', true, true },
    { 'dir', 'diaer', '', true, true },
    { 'ci', 'circle', '', true, true },
    { 'td', 'tilde', '', true, true },
    { 'nr', 'norm', '', true, true },
    { 'arw', 'arrow', '', true, true },
    { 'vv', 'vec', '', true, true },
    { 'rt', 'sqrt', '', true, true },
    { 'flr', 'floor', '', true, true },
    { 'cel', 'ceil', '', true, true },
}

local smart_wrap = function(_, snippet, _, user_args)
    local expand, is_postfix = user_args.expand, user_args.is_postfix
    local trigger = expand[1]
    local keep_brackets = expand[4]
    local add_brackets = expand[5]
    local expand_l = expand[2]
    local expand_r = expand[3]
    local expand_l_br = add_brackets and expand_l .. '(' or expand_l
    local expand_r_br = add_brackets and expand_r .. ')' or expand_r
    local ts_match = snippet.env.LS_TSMATCH
    if ts_match then
        ts_match = table.concat(ts_match, '\n')
    else
        ts_match = ''
    end

    local split_result = function(res, text_only)
        local text = t(vim.split(res, '\n', { trimempty = false }))
        if text_only then return text end
        return s(nil, text)
    end

    -- visual selection
    if not visual_disable[trigger] and #snippet.env.LS_SELECT_RAW > 0 then
        return split_result(ts_match .. expand_l_br .. table.concat(snippet.env.LS_SELECT_DEDENT, '\n') .. expand_r_br)
    end

    -- postfix
    if is_postfix then
        if ts_match then
            local replacement = ts_match
            if snippet.env.LS_TSCAPTURE_WRAPNOBRACKETS then
                if not keep_brackets then replacement = replacement:sub(2, -2) end
            elseif snippet.env.LS_TSCAPTURE_WRAP then
                expand_l, expand_r = expand_l_br, expand_r_br
            end
            replacement = expand_l .. replacement .. expand_r
            return split_result(replacement)
        end
    end

    -- normal snippet
    if not visual_disable_normal[trigger] then
        return s(nil, { split_result(ts_match .. expand_l_br, true), i(1, '1+1'), t(expand_r_br) })
    else
        return split_result(ts_match .. trigger)
    end
end

local query_string = '[ (call) (apply) (ident) (letter) (number) ] @wrap (group) @wrapnobrackets'

for _, val in pairs(operations) do
    local trig = val[1]
    table.insert(
        snippets,
        snip(trig, '<>', {
            d(1, smart_wrap, {}, { user_args = { { expand = val, is_postfix = false } } }),
        }, math, 1500)
    )

    if not visual_disable_postfix[trig] then
        table.insert(
            snippets,
            snip(
                trig,
                '<>',
                { d(1, smart_wrap, {}, { user_args = { { expand = val, is_postfix = true } } }) },
                math,
                1600,
                {
                    wordTrig = false,
                    baseSnip = ts_postfix,
                    context = {
                        reparseBuffer = 'live',
                        matchTSNode = {
                            query = query_string,
                            query_lang = 'typst',
                            match_captures = { 'wrap', 'wrapnobrackets' },
                            select = 'shortest',
                        },
                    },
                }
            )
        )
    end
end

return snippets
