local M = {}
local config = require('typstar.config')
local utils = require('typstar.utils')

local cfg = config.config.excalidraw
local affix = [[
#figure(
  image("%s"),
)
]]

local function launch_obsidian(path)
    print(string.format('Opening %s in Excalidraw', path))
    utils.run_shell_command(
        string.format('%s "obsidian://open?path=%s"', cfg.uriOpenCommand, utils.urlencode(path)),
        false
    )
end

function M.insert_drawing()
    local assets_dir = vim.fn.expand('%:p:h') .. '/' .. cfg.assetsDir
    local filename = os.date(cfg.filename)
    local path = assets_dir .. '/' .. filename .. cfg.fileExtension
    local path_inserted = cfg.assetsDir .. '/' .. filename .. cfg.fileExtensionInserted

    if vim.fn.isdirectory(assets_dir) == 0 then vim.fn.mkdir(assets_dir, 'p') end
    local found_match = false
    for pattern, template_path in pairs(cfg.templatePath) do
        if string.match(path, pattern) then
            found_match = true
            utils.run_shell_command(string.format('cat %s > %s', template_path, path), false) -- don't copy file metadata
            break
        end
    end
    if not found_match then
        print('No matching template found for the path: ' .. path)
        return
    end

    utils.insert_text_block(string.format(affix, path_inserted))
    launch_obsidian(path)
end

function M.open_drawing()
    local line = vim.api.nvim_get_current_line()
    local path = vim.fn.expand('%:p:h')
        .. '/'
        .. string.match(line, '"(.*)' .. string.gsub(cfg.fileExtensionInserted, '%.', '%%%.'))
        .. '.excalidraw.md'
    launch_obsidian(path)
end

return M
