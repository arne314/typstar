local helper = require('tests.helper'):setup()

local all_snippets = require('typstar.snippets.math')
local utils = require('typstar.utils')
local all_snippet_triggers = {}
for i, snip in ipairs(all_snippets) do
    all_snippet_triggers[i] = snip.trigger
end

-- simple test cases
helper:add_cases('math', {
    ['symbols'] = function() helper:test_snip_math('faexoxx', 'forall exists times.o ') end,
    ['lim'] = function() helper:test_snip_math('limx\\j0\\jx', 'lim_(x -> 0) x') end,
    ['limsup'] = function() helper:test_snip_math('limx\\j0\\jsupx', 'limsup_(x -> 0) x') end,
    ['superscript'] = function() helper:test_snip_math('aivbsrMcmp', 'a^(-1) b^2 M^complement ') end,
})

-- ensure space at end of expanded snippets
local ensure_space = {}
local ensure_space_ignore = { 'ccs', 'set', 'Sq' }
local ensure_space_ignore_set = {}
utils.generate_bool_set(ensure_space_ignore, ensure_space_ignore_set)
for _, trigger in ipairs(all_snippet_triggers) do
    if not ensure_space_ignore_set[trigger] and not trigger:match('[\\%(%)%[%]]') then
        ensure_space[trigger] = function()
            local buf = helper:eval_snip(trigger, 'math')
            helper.truthy(buf:match(' %$$'))
        end
    end
end
helper:add_cases('math_ensure_space', ensure_space)

return helper.test_set
