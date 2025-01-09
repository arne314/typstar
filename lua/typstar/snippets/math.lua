local ls = require('luasnip')
local i = ls.insert_node

local helper = require('typstar.autosnippets')
local snip = helper.snip
local math = helper.in_math
local cap = helper.cap

return {
    snip('fa', 'forall ', {}, math),
    snip('ex', 'exists ', {}, math),
    snip('ni', 'in.not ', {}, math),
    snip('Sq', 'square', {}, math),

    -- logical chunks
    snip('fen', 'forall epsilon>>0 ', {}, math),
    snip('fdn', 'forall delta>>0 ', {}, math),
    snip('edn', 'exists delta>>0 ', {}, math),
    snip('een', 'exists epsilon>>0 ', {}, math),

    -- boolean logic
    snip('no', 'not ', {}, math),
    snip('ip', '==>> ', {}, math),
    snip('ib', '<<== ', {}, math),

    -- relations
    snip('el', '= ', {}, math),
    snip('df', ':= ', {}, math),
    snip('lt', '<< ', {}, math),
    snip('gt', '>> ', {}, math),
    snip('le', '<<= ', {}, math),
    snip('ne', '!= ', {}, math),
    snip('ge', '>>= ', {}, math),

    -- operators
    snip('ak([^k])', '+<>', { cap(1) }, math, 500, false),
    snip('sk([^k])', '-<>', { cap(1) }, math, 500, false),
    snip('oak', 'plus.circle ', {}, math, 1100),
    snip('bak', 'plus.square ', {}, math, 1100),
    snip('mak', 'plus.minus ', {}, math, 1100),
    snip('xx', 'times ', {}, math),
    snip('oxx', 'times.circle ', {}, math),
    snip('bxx', 'times.square ', {}, math),

    -- sets
    -- 'st' to '{<>} in ./visual.lua
    snip('set', '{<>|<>}', { i(1), i(2) }, math),
    snip('es', 'emptyset ', {}, math),
    snip('ses', '{emptyset} ', {}, math),
    snip('sp', 'supset ', {}, math),
    snip('sb', 'subset ', {}, math),
    snip('sep', 'supset.eq ', {}, math),
    snip('seb', 'subset.eq ', {}, math),
    snip('nn', 'sect ', {}, math),
    snip('uu', 'union ', {}, math),
    snip('bnn', 'sect.big ', {}, math, 1100),
    snip('buu', 'union.big ', {}, math, 1100),
    snip('swo', 'without ', {}, math),

    -- misc
    snip('to', '->> ', {}, math),
    snip('mt', '|->> ', {}, math),
    snip('Oo', 'compose ', {}, math),
    snip('iso', 'tilde.equiv ', {}, math),
    snip('ep', 'exp(<>) ', { i(1, '1') }, math),
    snip('rrn', 'RR^n ', {}, math),
    snip('cc', 'cases(\n\t<>\n)\\', { i(1, '1') }, math),
    snip('(.*)iv', '<>^(-1)', { cap(1) }, math),
    snip('(.*)sr', '<>^2', { cap(1) }, math),
    snip('(.*)jj', '<>_(<>)', { cap(1), i(1, 'n') }, math),
    snip('(.*)kk', '<>^(<>)', { cap(1), i(1, 'n') }, math),

    snip('ddx', '(d <>)(d <>)', { i(1, 'f'), i(2, 'x') }, math),
    snip('it', 'integral_(<>)^(<>)', { i(1, 'a'), i(2, 'b') }, math),
    snip('oit', 'integral_(Omega}', {}, math),
    snip('dit', 'integral_{<>}', { i(1, 'Omega') }, math),
    snip('sm', 'sum_(<>)^(<>)', { i(1, 'i=0'), i(2, 'oo') }, math),

    snip('lm', 'lim <>', { i(1, 'a_n') }, math),
    snip('lim', 'lim_(<> ->> <>) <>', { i(1, 'n'), i(2, 'oo'), i(3, 'a_n') }, math),
    snip('lim (sup|inf)', 'lim<> <>', { cap(1), i(1, 'a_n') }, math),
    snip('lim(_.*-.*) (sup|inf)', 'lim<><> <>', { cap(2), cap(1), i(1, 'a_n') }, math),
}
