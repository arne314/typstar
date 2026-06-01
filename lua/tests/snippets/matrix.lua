local helper = require('tests.helper'):setup()

helper:add_cases('matrix', {
    ['square'] = function() helper:test_snip_math('22ma ', 'mat(\n  1,  ;\n   , 1;\n)') end,
    ['rect'] = function() helper:test_snip_math('23ma ', 'mat(\n  1,  ,  ;\n   , 1,  ;\n)') end,
    ['rect2'] = function() helper:test_snip_math('32ma ', 'mat(\n  1,  ;\n   , 1;\n   ,  ;\n)') end,
    ['row'] = function() helper:test_snip_math('13ma ', 'mat(\n  1,  ,  ;\n)') end,
    ['column'] = function() helper:test_snip_math('31ma ', 'mat(\n  1;\n   ;\n   ;\n)') end,
    ['zero'] = function() helper:test_snip_math('05ma ', 'mat(\n  \n)') end,
    ['one'] = function() helper:test_snip_math('11ma ', 'mat(\n  1;\n)') end,
})

helper:add_cases('matrix_dots', {
    ['square'] = function()
        helper:test_snip_math('22ma.', 'mat(\n  1, dots.c, 0;\n  dots.v, dots.down, dots.v;\n  0, dots.c, 1;\n)')
    end,
    ['rect'] = function()
        helper:test_snip_math(
            '23ma.',
            'mat(\n  1, 0, dots.c, 0;\n  dots.v, dots.v, dots.down, dots.v;\n  0, 1, dots.c, 0;\n)'
        )
    end,
    ['rect2'] = function()
        helper:test_snip_math(
            '32ma.',
            'mat(\n  1, dots.c, 0;\n  0, dots.c, 1;\n  dots.v, dots.down, dots.v;\n  0, dots.c, 0;\n)'
        )
    end,
    ['row'] = function() helper:test_snip_math('13ma.', 'mat(\n  1, 0, dots.c, 0;\n)') end,
    ['column'] = function() helper:test_snip_math('31ma.', 'mat(\n  1;\n  0;\n  dots.v;\n  0;\n)') end,
    ['zero'] = function() helper:test_snip_math('00ma.', 'mat(\n  \n)') end,
    ['one'] = function() helper:test_snip_math('11ma.', 'mat(\n  1;\n)') end,
})

return helper.test_set
