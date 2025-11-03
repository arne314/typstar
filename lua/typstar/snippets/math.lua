local ls = require('luasnip')
local i = ls.insert_node

local helper = require('typstar.autosnippets')
local snip = helper.snip
local math = helper.in_math
local cap = helper.cap

return {
    snip('fa', 'forall ', {}, math),
    snip('ex', 'exists ', {}, math),
    snip('Sq', 'square', {}, math),

    -- logical chunks
    snip('fen', 'forall epsilon>>0 ', {}, math),
    snip('fdn', 'forall delta>>0 ', {}, math),
    snip('edn', 'exists delta>>0 ', {}, math),
    snip('een', 'exists epsilon>>0 ', {}, math),

    -- boolean logic
    snip('and', 'and ', {}, math),
    snip('or', 'or ', {}, math),
    snip('not', 'not ', {}, math),
    snip('ip', '==>> ', {}, math),
    snip('ib', '<<== ', {}, math),
    snip('iff', '<<==>> ', {}, math),

    -- relations
    snip('el', '= ', {}, math),
    snip('df', ':= ', {}, math),
    snip('lt', '<< ', {}, math),
    snip('gt', '>> ', {}, math),
    snip('le', '<<= ', {}, math),
    snip('ne', '!= ', {}, math),
    snip('ge', '>>= ', {}, math),

    -- operators
    snip('mak', 'plus.minus ', {}, math),
    snip('oak', 'plus.circle ', {}, math),
    snip('bak', 'plus.square ', {}, math),
    snip('osk', 'minus.circle ', {}, math),
    snip('bsk', 'minus.square ', {}, math),
    snip('xx', 'times ', {}, math),
    snip('oxx', 'times.circle ', {}, math),
    snip('bxx', 'times.square ', {}, math),
    snip('ff', '(<>) / (<>) <>', { i(1, 'a'), i(2, 'b'), i(3) }, math),

    -- subscript/superscript
    snip('iv', '^(-1) ', {}, math, 500, { wordTrig = false, blacklist = { 'equiv' } }),
    snip('tp', '^top ', {}, math, 500, { wordTrig = false }),
    snip('cmp', '^complement ', {}, math, 500, { wordTrig = false }),
    snip('prp', '^perp ', {}, math, 500, { wordTrig = false }),
    snip('sr', '^2 ', {}, math, 500, { wordTrig = false }),
    snip('cb', '^3 ', {}, math, 500, { wordTrig = false }),
    snip('jj', '_(<>) ', { i(1, 'n') }, math, 500, { wordTrig = false }),
    snip('kk', '^(<>) ', { i(1, 'n') }, math, 500, { wordTrig = false }),

    -- sets
    -- 'st' to '{<>}' in ./visual.lua
    snip('set', '{<> mid(|) <>}', { i(1), i(2) }, math),
    snip('es', 'emptyset ', {}, math),
    snip('ses', '{emptyset} ', {}, math),
    snip('sp', 'supset ', {}, math),
    snip('sb', 'subset ', {}, math),
    snip('sep', 'supset.eq ', {}, math),
    snip('seb', 'subset.eq ', {}, math),
    snip('nn', 'inter ', {}, math),
    snip('uu', 'union ', {}, math),
    snip('bnn', 'inter.big ', {}, math),
    snip('buu', 'union.big ', {}, math),
    snip('swo', 'without ', {}, math),
    snip('ni', 'in.not ', {}, math),

    -- misc
    snip('to', '->> ', {}, math),
    snip('mt', '|->> ', {}, math),
    snip('cp', 'compose ', {}, math),
    snip('iso', 'tilde.equiv ', {}, math),
    snip('nab', 'nabla ', {}, math),
    snip('ep', 'exp(<>) ', { i(1, '1') }, math),
    snip('cc', 'cases(\n\t<>\n)\\', { i(1, '1') }, math),
    snip('([A-Za-z])o([A-Za-z0-9]) ', '<>(<>) ', { cap(1), cap(2) }, math, 100, {
        maxTrigLength = 4,
        blacklist = { 'bot ', 'cos ', 'cot ', 'dot ', 'log ', 'mod ', 'not ', 'top ', 'won ', 'xor ' },
    }),
    snip('(K|M|N|Q|R|S|Z)([\\dn]) ', '<><>^<> ', { cap(1), cap(1), cap(2) }, math),

    -- derivatives
    snip('dx', 'dif / (dif <>) ', { i(1, 'x') }, math),
    snip('ddx', '(dif <>) / (dif <>) ', { i(1, 'f'), i(2, 'x') }, math),
    snip('DX', 'diff / (diff <>) ', { i(1, 'x') }, math),
    snip('DDX', '(diff <>) / (diff <>) ', { i(1, 'f'), i(2, 'x') }, math),
    snip('part', 'partial ', {}, math, 1600),

    -- integrals
    snip('it', 'integral ', {}, math),
    snip('int', 'integral_(<>)^(<>) ', { i(1, 'a'), i(2, 'b') }, math),
    snip('oit', 'integral.cont_(<>) ', { i(1, 'C') }, math),
    snip('dit', 'integral_(<>) ', { i(1, 'Omega') }, math),

    -- sums
    snip('sm', 'sum ', {}, math),
    snip('sum', 'sum_(<>)^(<>) ', { i(1, 'k=1'), i(2, 'oo') }, math),
    snip('dsm', 'sum_(<>) ', { i(1, 'Omega') }, math),

    -- products
    snip('prd', 'product ', {}, math),
    snip('prod', 'product_(<>)^(<>) ', { i(1, 'k=1'), i(2, 'n') }, math),

    -- limits
    snip('lm', 'lim ', {}, math),
    snip('lim', 'lim_(<> ->> <>) ', { i(1, 'n'), i(2, 'oo') }, math),
    snip('lim (sup|inf)', 'lim<> ', { cap(1) }, math),
    snip(
        'lim(_\\(\\s?\\w+\\s?->\\s?\\w+\\s?\\)) (sup|inf)',
        'lim<><> ',
        { cap(2), cap(1) },
        math,
        nil,
        { maxTrigLength = 25 }
    ),
}
