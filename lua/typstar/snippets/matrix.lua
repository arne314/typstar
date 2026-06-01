local ls = require('luasnip')
local i = ls.insert_node
local d = ls.dynamic_node
local s = ls.snippet_node
local t = ls.text_node
local r = ls.restore_node

local helper = require('typstar.autosnippets')
local snip = helper.snip
local math = helper.in_math

local parse_nums = function(snippet)
    local rows = tonumber(snippet.captures[1])
    local cols = tonumber(snippet.captures[2])
    if rows == 0 or cols == 0 then return s(nil, i(1, '')), nil, nil end
    return nil, rows, cols
end

local mat = function(_, sp)
    local replace, rows, cols = parse_nums(sp)
    if replace ~= nil then return replace end
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
    return s(nil, nodes)
end

local dotmat = function(_, sp)
    local replace, rows, cols = parse_nums(sp)
    if replace ~= nil then return replace end
    local nodes = {}
    local ins_indx = 1
    for j = 1, rows do
        if j == rows and j ~= 1 then
            local last = cols
            if cols > 1 then last = cols + 1 end
            for k = 1, last do
                if k == last then
                    table.insert(nodes, t('dots.v'))
                elseif k == cols then
                    table.insert(nodes, t('dots.down, '))
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
    return s(nil, nodes)
end

return {
    snip('(\\d)(\\d)ma ', 'mat(\n\t<>\n)', { d(1, mat) }, math, 1500),
    snip('(\\d)(\\d)ma.', 'mat(\n\t<>\n)', { d(1, dotmat) }, math, 1500),
}
