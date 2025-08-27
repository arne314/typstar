local ls = require('luasnip')
local d = ls.dynamic_node
local i = ls.insert_node
local s = ls.snippet_node
local t = ls.text_node
local helper = require('typstar.autosnippets')
local utils = require('typstar.utils')
local snip = helper.snip
local cap = helper.cap
local math = helper.in_math
local markup = helper.in_markup

local greek_letters_map = {
    ['a'] = 'alpha',
    ['b'] = 'beta',
    ['c'] = 'chi',
    ['d'] = 'delta',
    ['e'] = 'epsilon',
    ['f'] = 'phi', -- sound
    ['g'] = 'gamma',
    ['h'] = 'eta', -- look
    ['i'] = 'iota',
    ['k'] = 'kappa',
    ['l'] = 'lambda',
    ['m'] = 'mu',
    ['n'] = 'nu',
    ['o'] = 'omikron',
    ['p'] = 'psi',
    ['q'] = 'theta', -- look?
    ['r'] = 'rho',
    ['s'] = 'sigma',
    ['t'] = 'tau',
    ['u'] = 'upsilon',
    ['v'] = 'nu', -- look
    ['w'] = 'omega', -- look
    ['x'] = 'xi',
    ['y'] = 'upsilon', -- look
    ['z'] = 'zeta',
}

local greek_keys = {}
local greek_letters_set = {}
local common_indices = { '\\d+', '[i-n]' }
-- builtins and calligraphic letters from github.com/lentilus/typst-scribe
local index_conflicts = { 'Im', 'in', 'ln', 'Pi', 'pi', 'Xi', 'xi', 'Ii', 'Jj', 'Kk', 'Ll', 'Mm', 'Nn' }
local index_conflicts_set = {}
local punctuation_prepend_space = { ',', ';' }
local punctuation_prepend_space_set = {}
local trigger_greek = ''
local trigger_index_pre = ''
local trigger_index_post = ''

local upper_first = function(str) return str:sub(1, 1):upper() .. str:sub(2, -1) end

local greek_full = {}
for latin, greek in pairs(greek_letters_map) do
    greek_full[latin] = greek
    greek_full[latin:upper()] = upper_first(greek)
    if not greek_letters_set[greek] then
        table.insert(greek_letters_set, greek)
        table.insert(greek_letters_set, upper_first(greek))
    end
    table.insert(greek_keys, latin)
    table.insert(greek_keys, latin:upper())
end

utils.generate_bool_set(index_conflicts, index_conflicts_set)
utils.generate_bool_set(punctuation_prepend_space, punctuation_prepend_space_set)

greek_letters_map = greek_full
trigger_greek = table.concat(greek_keys, '|')
trigger_index_pre = '[A-Za-z]' .. '|' .. table.concat(greek_letters_set, '|')
trigger_index_post = table.concat(common_indices, '|')

local get_greek = function(_, snippet) return s(nil, t(greek_letters_map[snippet.captures[1]])) end

local get_index = function(_, snippet, _, idx1, idx2, check_conflict)
    local letter, index = snippet.captures[idx1], snippet.captures[idx2]
    local trigger = letter .. index
    if check_conflict and index_conflicts_set[trigger] then return s(nil, t(trigger)) end
    return s(nil, t(letter .. '_' .. index))
end

local get_series = function(_, snippet)
    local letter, target = snippet.captures[1], snippet.captures[2]
    local target_num = tonumber(target)
    local result
    if target_num then
        local res = {}
        for n = 1, target_num do
            table.insert(res, string.format('%s_%d', letter, n))
            if n ~= target_num then table.insert(res, ', ') end
        end
        result = table.concat(res, '')
    else
        result = string.format('%s_1, %s_2, ..., %s_%s', letter, letter, letter, target)
    end
    return s(nil, t(result))
end

local prepend_space = function(_, snippet, _, idx)
    local punc = snippet.captures[idx]
    if punctuation_prepend_space_set[punc] then punc = punc .. ' ' end
    return s(nil, t(punc))
end

return {
    -- latin/greek
    snip(':([A-Za-z0-9])', '$<>$ ', { cap(1) }, markup),
    snip(';(' .. trigger_greek .. ')', '$<>$ ', { d(1, get_greek) }, markup),
    snip(';(' .. trigger_greek .. ')', '<>', { d(1, get_greek) }, math),

    -- indices
    snip(
        '\\$(' .. trigger_index_pre .. ')\\$' .. ' (' .. trigger_index_post .. ')([^\\w])',
        '$<>$<>',
        { d(1, get_index, {}, { user_args = { 1, 2, false } }), d(2, prepend_space, {}, { user_args = { 3 } }) },
        markup,
        500,
        { maxTrigLength = 13 }
    ),
    snip(
        '(' .. trigger_index_pre .. ')' .. '(' .. trigger_index_post .. ')([^\\w])',
        '<><>',
        { d(1, get_index, {}, { user_args = { 1, 2, true } }), d(2, prepend_space, {}, { user_args = { 3 } }) },
        math,
        200,
        { maxTrigLength = 10 } -- epsilon123
    ),

    -- series of numbered letters
    snip('ot(\\w) ', '1, 2, ..., <> ', { cap(1) }, math, 800), -- 1, 2, ..., n
    snip('(' .. trigger_index_pre .. ') ot ', '<>_1, <>_2, ... ', { cap(1), cap(1) }, math), -- a_1, a_2, ...
    snip('(' .. trigger_index_pre .. ') ot(\\w+) ', '<> ', { d(1, get_series) }, math, nil, { maxTrigLength = 13 }), -- a_1, a_2, ... a_j or a_1, a_2, a_2, a_3, a_4, a_5

    -- misc
    snip('(' .. trigger_index_pre .. ')bl', 'B_<> (<>) ', { cap(1), i(1, 'x_0') }, math, 100),
}
