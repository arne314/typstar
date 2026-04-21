local helper = require('tests.helper'):setup()

helper:add_cases('visual_selection', {
    ['markup'] = function() helper:test_snip('kk', '$a+b+c$') end,
    ['markup_multiline'] = function() helper:test_snip('thm', '#theorem[\n  a+b+c\n]') end,
    ['precedence'] = function() helper:test_snip_math('(a)ht', '(a)hat(a+b+c)') end,
    ['precedence2'] = function() helper:test_snip_math('aht', 'ahat(a+b+c)') end,
    ['nested'] = function()
        helper:set_buffer('$root(\\C)$')
        helper:test_snip('ht', '$root(hat(a+b+c))$')
    end,
}, {
    setup = function() helper:store_selection('a+b+c') end,
})

helper:add_cases('visual_postfix', {
    ['postfix'] = function() helper:test_snip_math('aht', 'hat(a)') end,
    ['long'] = function() helper:test_snip_math('alphaht', 'hat(alpha)') end,
    ['long2'] = function() helper:test_snip_math('hat(b)alphaht', 'hat(b)hat(alpha)') end,
    ['long3'] = function()
        helper:set_buffer('$hat(a)b\\C hat(c)$')
        helper:test_snip('ht', '$hat(a)hat(b) hat(c)$')
    end,
    ['nested'] = function() helper:test_snip_math('artht', 'hat(sqrt(a))') end,
    ['nested2'] = function()
        helper:set_buffer('$sqrt(abs(a^2\\C) + b^2)$')
        helper:test_snip('ht', '$sqrt(abs(a^hat(2)) + b^2)$')
    end,
    ['precedence'] = function() helper:test_snip_math('a_alphaht', 'a_hat(alpha)') end,
    ['precedence2'] = function() helper:test_snip_math('a_b_alphaht', 'a_b_hat(alpha)') end,
    ['brackets'] = function() helper:test_snip_math('(a)ht', 'hat(a)') end,
    ['brackets2'] = function() helper:test_snip_math('(a)sq', '[(a)]') end,
    ['brackets3'] = function() helper:test_snip_math('(a)sQ', '[a]') end,
    ['brackets4'] = function() helper:test_snip_math('[a]BB', 'a') end,
    ['brackets5'] = function() helper:test_snip_math('([a])BB', '[a]') end,
    ['index'] = function() helper:test_snip_math('b_aht', 'b_hat(a)') end,
    ['index_brackets'] = function() helper:test_snip_math('b_(a)ht', 'b_hat(a)') end,
    ['multiline'] = function()
        helper:set_buffer('$sqrt(a\nb)\\C$')
        helper:test_snip('ht', '$hat(sqrt(a\nb))$')
    end,
    ['multiline2'] = function()
        helper:set_buffer('$(0+sqrt(a^2\n+[b^2])\t\n=c)\\C$')
        helper:test_snip('ht', '$hat(0+sqrt(a^2\n+[b^2]) \n=c)$')
    end,
})

helper:add_cases('visual_normal', {
    ['normal'] = function() helper:test_snip_math('hta\\j b', 'hat(a) b') end,
    ['long'] = function() helper:test_snip_math('ht;a\\j b', 'hat(alpha) b') end,
    ['nested'] = function()
        helper:set_buffer('$root(\\C)$')
        helper:test_snip('rta\\j b', '$root(sqrt(a) b)$')
    end,
})

return helper.test_set
