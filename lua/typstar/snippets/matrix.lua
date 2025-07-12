local ls = require('luasnip')
local i = ls.insert_node
local d = ls.dynamic_node
local sn = ls.snippet_node
local t = ls.text_node
local r = ls.restore_node

local helper = require('typstar.autosnippets')
local snip = helper.snip
local math = helper.in_math

-- generating function
local mat = function(_, sp)
    local rows = tonumber(sp.captures[1])
    local cols = tonumber(sp.captures[2])
    local nodes = {}
    local ins_indx = 1
    for j = 1, rows do
        if j == 1 then
            table.insert(nodes, r(ins_indx, tostring(j) .. 'x1', i(1, '1')))
        else
            table.insert(nodes, r(ins_indx, tostring(j) .. 'x1', i(1, ' ')))
        end
        ins_indx = ins_indx + 1
        for k = 2, cols do
            table.insert(nodes, t(', '))
            if j == k then
                table.insert(nodes, r(ins_indx, tostring(j) .. 'x' .. tostring(k), i(1, '1')))
            else
                table.insert(nodes, r(ins_indx, tostring(j) .. 'x' .. tostring(k), i(1, ' ')))
            end
            ins_indx = ins_indx + 1
        end
        table.insert(nodes, t({ ';', '\t' }))
    end
    nodes[#nodes] = t(';')
    return sn(nil, nodes)
end

local lmat = function(_, sp)
    local rows = tonumber(sp.captures[1])
    local cols = tonumber(sp.captures[2])
    local nodes = {}
    local ins_indx = 1
    for j = 1, rows do
        if j == rows then
            for k = 1, cols + 1 do
                if k == cols then
                    table.insert(nodes, t('dots.down, '))
                elseif k == cols + 1 then
                    table.insert(nodes, t('dots.v'))
                else
                    table.insert(nodes, t('dots.v, '))
                end
            end
            table.insert(nodes, t({ ';', '\t' }))
        end
        if j == 1 then
            table.insert(nodes, r(ins_indx, tostring(j) .. 'x1', i(1, '1')))
        else
            table.insert(nodes, r(ins_indx, tostring(j) .. 'x1', i(1, '0')))
        end
        ins_indx = ins_indx + 1
        for k = 2, cols do
            table.insert(nodes, t(', '))
            if k == cols then table.insert(nodes, t('dots.c, ')) end
            if j == k then
                table.insert(nodes, r(ins_indx, tostring(j) .. 'x' .. tostring(k), i(1, '1')))
            else
                table.insert(nodes, r(ins_indx, tostring(j) .. 'x' .. tostring(k), i(1, '0')))
            end
            ins_indx = ins_indx + 1
        end
        table.insert(nodes, t({ ';', '\t' }))
    end
    nodes[#nodes] = t(';')
    return sn(nil, nodes)
end

return {
    snip('(\\d)(\\d)ma', 'mat(\n\t<>\n)', { d(1, mat) }, math),
    snip('(\\d)(\\d)lma', 'mat(\n\t<>\n)', { d(1, lmat) }, math),
}
