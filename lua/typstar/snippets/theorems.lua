local helper = require('typstar.autosnippets')

local indent_visual = function(idx, default) return helper.visual(idx, default or '', '\t', 1) end

local environments = {
    { 'thm', 'theorem' },
    { 'prf', 'proof' },
    { 'prp', 'proposition' },
    { 'axm', 'axiom' },
    { 'crl', 'corollary' },
    { 'lmm', 'lemma' },
    { 'dfn', 'definition' },
    { 'exm', 'example' },
    { 'rmr', 'remark' },
}

local theorem_snippets = {}
local theorem_string = '#%s[\n<>\n<>]'

for _, val in pairs(environments) do
    table.insert(
        theorem_snippets,
        helper.start_snip(
            val[1],
            string.format(theorem_string, val[2]),
            { indent_visual(1), helper.cap(1) },
            helper.in_markup
        )
    )
end

return theorem_snippets
