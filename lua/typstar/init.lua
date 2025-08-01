local M = {}

local config = require('typstar.config')
local luasnip = nil

M.setup = function(args)
    config.merge_config(args)
    local autosnippets = require('typstar.autosnippets')
    local drawings = require('typstar.drawings')
    local anki = require('typstar.anki')

    vim.api.nvim_create_user_command('TypstarToggleSnippets', autosnippets.toggle_autosnippets, {})
    vim.api.nvim_create_user_command('TypstarSmartJump', function() M.smart_jump(1) end, {})
    vim.api.nvim_create_user_command('TypstarSmartJumpBack', function() M.smart_jump(-1) end, {})

    vim.api.nvim_create_user_command('TypstarInsertExcalidraw', drawings.insert_drawing, {})
    vim.api.nvim_create_user_command('TypstarOpenExcalidraw', drawings.open_drawing, {})

    vim.api.nvim_create_user_command('TypstarAnkiScan', anki.scan, {})
    vim.api.nvim_create_user_command('TypstarAnkiReimport', anki.scan_reimport, {})
    vim.api.nvim_create_user_command('TypstarAnkiForce', anki.scan_force, {})
    vim.api.nvim_create_user_command('TypstarAnkiForceReimport', anki.scan_force_reimport, {})
    vim.api.nvim_create_user_command('TypstarAnkiForceCurrent', anki.scan_force_current, {})
    vim.api.nvim_create_user_command('TypstarAnkiForceCurrentReimport', anki.scan_force_current_reimport, {})
    autosnippets.setup()
end

-- source: https://github.com/lentilus/fastex.nvim
M.smart_jump = function(length, x, y, tries)
    if luasnip == nil then luasnip = require('luasnip') end
    local x2, y2 = unpack(vim.api.nvim_win_get_cursor(0))
    local tries = tries or 0

    if tries > 10 then return end
    if x == nil or y == nil then
        x, y = x2, y2
    end
    if x == x2 and y == y2 then
        luasnip.jump(length)
        vim.schedule(function() M.smart_jump(length, x, y, tries + 1) end)
    end
end

return M
