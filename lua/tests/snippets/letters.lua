local helper = require('tests.helper'):setup()

helper:add_cases('letters', {
    ['markup'] = function() helper:test_snip(':A', '$A$ ') end,
    ['math'] = function() helper:test_snip_math(';A', 'Alpha') end,
    ['index'] = function() helper:test_snip(':b1 ', '$b_1$ ') end,
    ['index_greek'] = function() helper:test_snip(';b1 ', '$beta_1$ ') end,
    ['index_math'] = function() helper:test_snip_math(';a1 ', 'alpha_1 ') end,
    ['index_long'] = function() helper:test_snip(';e123 ', '$epsilon_123$ ') end,
    ['punctuation'] = function() helper:test_snip('$Xi$ 5.', '$Xi_5$.') end,
    ['punctuation2'] = function() helper:test_snip('$Xi$ 5,', '$Xi_5$, ') end,
    ['conflict'] = function() helper:test_snip_math('Pi ', 'Pi ') end,
    ['series'] = function() helper:test_snip_math('otk ', '1, 2, ..., k ') end,
    ['series2'] = function() helper:test_snip_math('alpha otm ', 'alpha_1, alpha_2, ..., alpha_m ') end,
    ['series3'] = function() helper:test_snip_math('alpha ot ', 'alpha_1, alpha_2, ... ') end,
    ['ball'] = function() helper:test_snip_math(';eblz\\ja', 'B_epsilon (z) a') end,
})

return helper.test_set
