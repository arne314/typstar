local ls = require('luasnip')
local i = ls.insert_node

local helper = require('typstar.autosnippets')
local cap = helper.cap
local markup = helper.in_markup
local visual = helper.visual
local snip = helper.snip
local start = helper.start_snip

local ctheorems = {
    { 'tem', 'theorem' },
    { 'pro', 'proof' },
    { 'axi', 'axiom' },
    { 'cor', 'corollary' },
    { 'lem', 'lemma' },
    { 'def', 'definition' },
    { 'exa', 'example' },
    { 'rem', 'remark' },
}

local wrappings = {
    { 'll', '$', '$', '1+1' },
    { 'BLD', '*', '*', 'abc' },
    { 'ITL', '_', '_', 'abc' },
    { 'HIG', '#highlight[', ']', 'abc' },
    { 'UND', '#underline[', ']', 'abc' },
}

local document_snippets = {}
local ctheoremsstr = '#%s[\n<>\t<>\n<>]'
local wrappingsstr = '%s<>%s'

for _, val in pairs(ctheorems) do
    local snippet = start(val[1], string.format(ctheoremsstr, val[2]), { cap(1), visual(1), cap(1) }, markup)
    table.insert(document_snippets, snippet)
end

for _, val in pairs(wrappings) do
    local snippet = snip(val[1], string.format(wrappingsstr, val[2], val[3]), { visual(1, val[4]) }, markup)
    table.insert(document_snippets, snippet)
end

return {
    start('dm', '$\n<>\t<>\n<>$', { cap(1), visual(1), cap(1) }, markup),
    helper.start_snip_in_newl(
        'dm',
        '$\n<>\t<>\n<>$',
        { helper.leading_white_spaces(1), visual(1), helper.leading_white_spaces(1) },
        markup
    ),
    start('fla', '#flashcard(0)[<>][\n<>\t<>\n<>]', { i(1, 'flashcard'), cap(1), visual(2), cap(1) }, markup),
    start('flA', '#flashcard(0, "<>")[\n<>\t<>\n<>]', { i(1, 'flashcard'), cap(1), visual(2), cap(1) }, markup),
    snip('IMP', '$==>>$ ', {}, markup),
    snip('IFF', '$<<==>>$ ', {}, markup),
    unpack(document_snippets),
}
