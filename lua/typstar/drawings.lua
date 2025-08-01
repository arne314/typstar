local M = {}
local config = require('typstar.config')
local utils = require('typstar.utils')

local affix = [[
#figure(
  image("%s"),
)
]]
local config_excalidraw = config.config.excalidraw
local config_rnote = config.config.rnote

local function launch_excalidraw(path)
    print(string.format('Opening %s in Obsidian Excalidraw', path))
    utils.run_shell_command(
        string.format('%s "obsidian://open?path=%s"', config_excalidraw.uriOpenCommand, utils.urlencode(path)),
        false
    )
end

local function launch_rnote(path)
    print(string.format('Opening %s in Rnote', path))
    utils.run_shell_command(string.format('%s %s', config_rnote.uriOpenCommand, path), false)
end

local function insert_drawing(provider)
    local cfg = provider[1]
    local assets_dir = vim.fn.expand('%:p:h') .. '/' .. cfg.assetsDir
    local filename = os.date(cfg.filename)
    local path = assets_dir .. '/' .. filename .. cfg.fileExtension
    local path_inserted = cfg.assetsDir .. '/' .. filename .. cfg.fileExtensionInserted

    if vim.fn.isdirectory(assets_dir) == 0 then vim.fn.mkdir(assets_dir, 'p') end
    local found_match = false
    for _, template_config in ipairs(cfg.templatePath) do
        local pattern = template_config[1]
        local template_path = template_config[2]
        if string.match(path, pattern) then
            found_match = true
            utils.run_shell_command(string.format('cat %s > %s', template_path, path), false) -- don't copy file metadata
            break
        end
    end
    if not found_match then
        print('No matching template found for path: ' .. path)
        return
    end

    utils.insert_text_block(string.format(provider[2], path_inserted))
    provider[3](path)
end

local excalidraw = {
    config_excalidraw,
    affix,
    launch_excalidraw,
}
local rnote = {
    config_rnote,
    affix,
    launch_rnote,
}
local providers = { excalidraw, rnote }

function M.insert_obsidian_excalidraw() insert_drawing(excalidraw) end
function M.insert_rnote() insert_drawing(rnote) end

function M.open_drawing()
    for _, provider in pairs(providers) do
        local cfg = provider[1]
        local line = vim.api.nvim_get_current_line()
        local filename = line:match('"(.*)' .. string.gsub(cfg.fileExtensionInserted, '%.', '%%%.'))
        if filename ~= nil and filename:match('^%s*$') == nil then
            local path = vim.fn.expand('%:p:h') .. '/' .. filename .. cfg.fileExtension
            provider[3](path) -- launch program
            break
        end
    end
end

return M
