local helper = require('tests.helper'):setup()

-- ============================================================
-- auto-align.lua snippet tests
-- Trigger: (\S)\s+ali (wordTrig=false, math mode only)
-- Expansion: {cap} \\\n {insert="="} & {visual}
-- Post-expand callback: finds alignment target via treesitter,
--    inserts & at correct position in multi-line math.
-- ============================================================

helper:add_cases('auto_align_basic', {
    ['expand_eq'] = function()
        helper:test_snip_math('= ali', '= \\\n = & ')
    end,
    ['expand_one_space'] = function()
        helper:test_snip_math('< ali', '< \\\n = & ')
    end,
})

-- markup noexpand
helper:add_cases('auto_align_context', {
    ['no_expand_in_markup'] = function()
        helper:test_snip('= ali')
    end,
    ['no_expand_no_operator'] = function()
        helper:test_snip_math('ali')
    end,
})

function ali_wrapper(string1, string2, changeop)
    helper:set_buffer(string1)
    helper.child.bo.filetype = 'typst'
    helper.child.cmd('startinsert')
    helper.child.cmd('lua vim.treesitter.get_parser():parse()')

    local input = ' ali'
    for i = 1, #input do
        pcall(helper.child.type_keys, 3, string.char(input:byte(i)))
    end

    if changeop then
        for i = 1, #changeop do
            pcall(helper.child.type_keys, 3, string.char(changeop:byte(i)))
        end
    end

    helper:jump()
    helper.child.cmd('lua vim.wait(20, function() return false end)')
    local buf = table.concat(
        helper.child.api.nvim_buf_get_lines(0, 0, -1, true),
        '\n'
    )

    helper.eq(buf, string2)
end

helper:add_cases('auto_align_callback', {
    ['inline-align-naive'] = ali_wrapper('$ x = a\\C $', "$ x = & a \\\n = &  $"),
    ['multiline-align-naive'] = ali_wrapper('$\\\n x = a\\C \\\n$', "$\\\n x = & a \\\n  = &  \\\n$"),
    ['subscript-align'] = ali_wrapper('$\\\n a = b + sum_( k = 0\\C)\\\n$',
        "$\\\n a = b + sum_( k = & 0 \\\n  = & )\\\n$"),
    ['subscript-align-2'] = ali_wrapper('$\\\n a = b + sum_( k = 0\\C)\\\n$',
        "$\\\n a = b + sum_( k = & 0 \\\n    & )\\\n$", " "),
    ['and-test'] = ali_wrapper('$ x = a\\C $', "$ & x = a \\\n and  &  $", "and"),
    ['or-test'] = ali_wrapper('$ x = a\\C $', "$ & x = a \\\n or  &  $", "or"),
    ['iff-test'] = ali_wrapper('$ x = a\\C $', "$ & x = a \\\n <==> &  $", "<==>"),
    ['==>-test'] = ali_wrapper('$ x = a\\C $', "$ & x = a \\\n ==> &  $", "==>"),

    ['multiple-operators'] = ali_wrapper('$ A <==> B <==> C <==> D\\C $', "$ A <==> & B <==> C <==> D \\\n ==> &  $",
        "==>"),
    ['multiple-operators2'] = ali_wrapper('$ A = B <==> C = D\\C $', "$ A = B <==> & C = D \\\n ==> &  $", "==>"),
    ['multiple-operators3'] = ali_wrapper('$ A = B <==> C = D\\C $', "$ A = B <==> C = & D \\\n = &  $"),

    ['ignore_eq_in_fun'] = ali_wrapper('$ norm(a = b)\\C $', "$ & norm(a = b) \\\n = &  $"),
    ['ignore_eq_in_grp'] = ali_wrapper('$ a_(a = b)\\C $', "$ & a_(a = b) \\\n = &  $"),
})



return helper.test_set
