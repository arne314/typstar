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
    ['o'] = 'omicron',
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
local index_blacklist = { 'Im', 'in', 'ln', 'Pi', 'pi', 'Xi', 'xi', 'Ii', 'Jj', 'Kk', 'Ll', 'Mm', 'Nn' }
local index_blacklist_set = {}
local index_blacklist_full = {}
local punctuation_prepend_space = { ',', ';', "'" }
local punctuation_prepend_space_set = {}
local trigger_greek = ''
local trigger_index_pre = ''
local trigger_index_post = ''
utils.generate_bool_set(index_blacklist, index_blacklist_set)
utils.generate_bool_set(punctuation_prepend_space, punctuation_prepend_space_set)

local upper_first = function(str) return str:sub(1, 1):upper() .. str:sub(2, -1) end

-- fill blacklist
for _, conflict in ipairs(index_blacklist) do
    table.insert(index_blacklist_full, conflict .. ' ')
    for punct in pairs(punctuation_prepend_space_set) do
        table.insert(index_blacklist_full, conflict .. punct)
    end
end

-- fill latin greek map
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

greek_letters_map = greek_full
trigger_greek = table.concat(greek_keys, '|')
trigger_index_pre = '[A-Za-z]' .. '|' .. table.concat(greek_letters_set, '|') .. '|Pi|pi'
trigger_index_post = table.concat(common_indices, '|')

local get_greek = function(_, snippet) return s(nil, t(greek_letters_map[snippet.captures[1]])) end

local get_index = function(_, snippet, _, idx_letter, idx_prime, idx_index, check_conflict)
    local letter, prime, index = snippet.captures[idx_letter], snippet.captures[idx_prime], snippet.captures[idx_index]
    local trigger = letter .. index
    if check_conflict and prime == '' and index_blacklist_set[trigger] then return s(nil, t(trigger)) end
    if snippet.trigger:sub(-1) == "'" then prime = "'" end
    return s(nil, t(letter .. prime .. '_' .. index))
end

local get_series = function(_, snippet)
    local letter, start, stop = snippet.captures[1], snippet.captures[2], snippet.captures[3]
    local start_zero = start == 'z'
    local target_num = tonumber(stop)
    local result
    if target_num then
        local res = {}
        for n = (start_zero and 0 or 1), target_num do
            table.insert(res, string.format('%s_%d', letter, n))
            if n ~= target_num then table.insert(res, ', ') end
        end
        result = table.concat(res, '')
    else
        if #stop > 1 then return s(nil, t(snippet.trigger:sub(1, -2))) end
        if start_zero then
            result = string.format('%s_0, %s_1, ..., %s_%s', letter, letter, letter, stop)
        else
            result = string.format('%s_1, %s_2, ..., %s_%s', letter, letter, letter, stop)
        end
    end
    return s(nil, t(result))
end

local prepend_space = function(_, snippet, _, idx)
    local punc = snippet.captures[idx]
    local res = punc
    if punc == "'" then res = '' end
    if punctuation_prepend_space_set[punc] then res = res .. ' ' end
    return s(nil, t(res))
end

return {
    -- latin/greek
    snip(':([A-Za-z0-9])', '$<>$ ', { cap(1) }, markup),
    snip(';(' .. trigger_greek .. ')', '$<>$ ', { d(1, get_greek) }, markup),
    snip(';(' .. trigger_greek .. ')', '<>', { d(1, get_greek) }, math),

    -- indices
    snip(
        '\\$(' .. trigger_index_pre .. ')\\$' .. " ('?)(" .. trigger_index_post .. ')([^\\w])',
        '$<>$<>',
        { d(1, get_index, {}, { user_args = { 1, 2, 3, false } }), d(2, prepend_space, {}, { user_args = { 4 } }) },
        markup,
        500,
        { maxTrigLength = 14 } -- $epsilon$ '123
    ),
    snip(
        '(' .. trigger_index_pre .. ')' .. "('?)(" .. trigger_index_post .. ')([^\\w])',
        '<><>',
        { d(1, get_index, {}, { user_args = { 1, 2, 3, true } }), d(2, prepend_space, {}, { user_args = { 4 } }) },
        math,
        200,
        { maxTrigLength = 11, blacklist = index_blacklist_full } -- epsilon'123
    ),

    -- series of numbered letters
    snip('([oz])t(\\w+) ', '<> ', {
        d(1, function(_, snippet)
            local start, stop = snippet.captures[1], snippet.captures[2]
            if #stop > 1 and not tonumber(stop) then return s(nil, t(snippet.trigger:sub(1, -2))) end
            local pre = start == 'z' and '0, 1' or '1, 2'
            return s(nil, t(pre .. ', ..., ' .. stop))
        end),
    }, math, 800, { maxTrigLength = 5 }), -- 1, 2, ..., n
    snip('(' .. trigger_index_pre .. ') ([oz])t ', '<>, ... ', {
        d(1, function(_, snippet)
            local letter, start = snippet.captures[1], snippet.captures[2]
            if start == 'z' then
                return s(nil, t(string.format('%s_0, %s_1', letter, letter)))
            else
                return s(nil, t(string.format('%s_1, %s_2', letter, letter)))
            end
        end),
    }, math), -- a_1, a_2, ...
    snip(
        '(' .. trigger_index_pre .. ') ([oz])t(\\w+) ',
        '<> ',
        { d(1, get_series) },
        math,
        nil,
        { maxTrigLength = 13 }
    ), -- a_1, a_2, ... a_j or a_1, a_2, a_2, a_3, a_4, a_5

    -- misc
    snip('(' .. trigger_index_pre .. ')bl', 'B_<> (<>) ', { cap(1), i(1, 'x_0') }, math, 100),
    snip(
        '\\$(' .. trigger_index_pre .. ")\\$ '([^\\w])",
        "$<>'$<>",
        { cap(1), d(1, prepend_space, {}, { user_args = { 2 } }) },
        markup,
        400,
        { maxTrigLength = 11 } -- $epsilon$ '
    ),
}
