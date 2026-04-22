local helper = require('tests.helper'):setup()

helper:add_cases('letters', {
    ['markup'] = function() helper:test_snip(':A', '$A$ ') end,
    ['math'] = function() helper:test_snip_math(';A', 'Alpha') end,
    ['index'] = function() helper:test_snip(':b1 ', '$b_1$ ') end,
    ['index_greek'] = function() helper:test_snip(';b1 ', '$beta_1$ ') end,
    ['index_math'] = function() helper:test_snip_math(';a1 ', 'alpha_1 ') end,
    ['index_long'] = function() helper:test_snip(';e123 ', '$epsilon_123$ ') end,
    ['index_factor'] = function() helper:test_snip_math('3;f1 ', '3phi_1 ') end,
    ['index_prime'] = function() helper:test_snip(";e123'", "$epsilon'_123$ ") end,
    ['index_prime2'] = function() helper:test_snip(";e'123 ", "$epsilon'_123$ ") end,
    ['punctuation'] = function() helper:test_snip('$Xi$ 5.', '$Xi_5$.') end,
    ['punctuation2'] = function() helper:test_snip('$Xi$ 5,', '$Xi_5$, ') end,
    ['punctuation3'] = function() helper:test_snip("$Xi$ '.", "$Xi'$.") end,
    ['punctuation4'] = function() helper:test_snip("$Xi$ ',", "$Xi'$, ") end,
    ['conflict'] = function() helper:test_snip_math('Pi ', 'Pi ') end,
    ['series'] = function() helper:test_snip_math('otk ', '1, 2, ..., k ') end,
    ['series2'] = function() helper:test_snip_math('zt5 ', '0, 1, ..., 5 ') end,
    ['series3'] = function() helper:test_snip_math('alpha otm ', 'alpha_1, alpha_2, ..., alpha_m ') end,
    ['series4'] = function() helper:test_snip_math('alpha ot ', 'alpha_1, alpha_2, ... ') end,
    ['series5'] = function() helper:test_snip_math('alpha ztk ', 'alpha_0, alpha_1, ..., alpha_k ') end,
    ['series6'] = function() helper:test_snip_math('a zt5 ', 'a_0, a_1, a_2, a_3, a_4, a_5 ') end,
    ['ball'] = function() helper:test_snip_math(';eblz\\ja', 'B_epsilon (z) a') end,
    ['prime'] = function() helper:test_snip(";e' ", "$epsilon'$ ") end,
})

return helper.test_set
