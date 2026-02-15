local helper = require('tests.helper'):setup()

helper:add_cases('treesitter_markup', {
    ['start'] = function() helper:test_snip('temabc', '#theorem[\n  abc\n]') end,
    ['no_start'] = function() helper:test_snip('1 temabc') end,
    ['no_math'] = function() helper:test_snip('asr') end,
    ['edge'] = function() helper:test_snip('$alpha$;a1 ', '$alpha$$alpha_1$ ') end,
    ['edge2'] = function()
        helper:set_buffer('\\C$alpha$')
        helper:test_snip(';a', '$alpha$ $alpha$')
    end,
    ['edge3'] = function()
        helper:set_buffer('$a$\\C$alpha$')
        helper:test_snip(';a', '$a$$alpha$ $alpha$')
    end,
    ['edge4'] = function() helper:test_snip('#{emoji.monkey};a1.', '#{emoji.monkey}$alpha_1$.') end,
    ['nested'] = function()
        helper:set_buffer('$ #[\\C] $')
        helper:test_snip(';a1,', '$ #[$alpha_1$, ] $')
    end,
    ['nested2'] = function()
        helper:set_buffer('$ #[$#[\\C]$] $')
        helper:test_snip(';a1,', '$ #[$#[$alpha_1$, ]$] $')
    end,
})

helper:add_cases('treesitter_math', {
    ['no_markup'] = function() helper:test_snip_math('tem\ndm') end,
    ['string'] = function()
        helper:set_buffer('$"\\C"$')
        helper:test_snip(';a ll', '$";a ll"$')
    end,
    ['string2'] = function()
        helper:set_buffer('$"a"\\C$')
        helper:test_snip(';a', '$"a"alpha$')
    end,
    ['string3'] = function()
        helper:set_buffer('$\\C"a"$')
        helper:test_snip(';a1 ', '$alpha_1 "a"$')
    end,
    ['edge'] = function() helper:test_snip_math(';a1 ;a', 'alpha_1 alpha') end,
    ['edge2'] = function() helper:test_snip_math(';a;a', 'alpha;a') end,
    ['edge3'] = function()
        helper:set_buffer('$\\Calpha$')
        helper:test_snip(';a1 ', '$alpha_1 alpha$')
    end,
    ['nested'] = function()
        helper:set_buffer('#{$\\C$}')
        helper:test_snip(';a1 ', '#{$alpha_1 $}')
    end,
    ['nested2'] = function()
        helper:set_buffer('#[$#[$\\C$]$]')
        helper:test_snip(';a1 ', '#[$#[$alpha_1 $]$]')
    end,
    ['nested3'] = function()
        helper:set_buffer('#[$#[$\\C$]$]')
        helper:test_snip('dm', '#[$#[$dm$]$]')
    end,
})

helper:add_cases('treesitter_code', {
    ['no_math'] = function() helper:test_snip_code('asr') end,
    ['no_markup'] = function() helper:test_snip_code('tem\ndm') end,
})

return helper.test_set
