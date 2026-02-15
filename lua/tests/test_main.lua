local helper = require('tests.helper'):setup()

return helper:add_cases('main', {
    ['jsregexp'] = function()
        local jsregexp_ok, _ = pcall(require, 'jsregexp')
        helper.eq(jsregexp_ok, true)
    end,
    ['toggle_snippets'] = function()
        helper:test_snip('\\t:a\\t :a', ':a $a$ ')
    end,
    ['jump'] = function()
        helper:test_snip_math('ff1\\j2\\b3\\j\\ja', '(3) / (2) a')
    end,
})
