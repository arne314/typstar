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

local function launch_excalidraw(path, path_inserted)
    print(string.format('Opening %s in Obsidian Excalidraw', path))
    utils.run_shell_command(
        string.format('%s "obsidian://open?path=%s"', config_excalidraw.uriOpenCommand, utils.urlencode(path)),
        false
    )
end

local rnote_watched = {}

local function auto_export_rnote(path, path_inserted)
    if rnote_watched[path] then return end
    rnote_watched[path] = true
    local job_id = -1
    local last_export = 0

    local run_export = function(err, filename)
        local time = vim.uv.now()
        if err ~= nil or time - last_export < 800 then return end

        if job_id == -1 then
            last_export = time
            local cmd = string.format(config_rnote.exportCommand, path_inserted, path)
            job_id = utils.run_shell_command(cmd, false, nil, { on_exit = function() job_id = -1 end })
        end
    end
    local watcher = vim.uv.new_fs_event()
    watcher:start(path, {}, vim.schedule_wrap(run_export))
end

local function launch_rnote(path, path_inserted)
    print(string.format('Opening %s in Rnote', path))
    utils.run_shell_command(string.format('%s %s', config_rnote.uriOpenCommand, path), false)
    auto_export_rnote(path, path_inserted)
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
    provider[3](path, path_inserted)
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

local open_drawing = function(prov)
    for _, provider in ipairs(prov) do
        local cfg = provider[1]
        local line = vim.api.nvim_get_current_line()
        local filename = line:match('"(.*)' .. string.gsub(cfg.fileExtensionInserted, '%.', '%%%.'))
        if filename ~= nil and filename:match('^%s*$') == nil then
            local path = vim.fn.expand('%:p:h') .. '/' .. filename .. cfg.fileExtension
            local path_inserted = vim.fn.expand('%:p:h') .. '/' .. filename .. cfg.fileExtensionInserted
            provider[3](path, path_inserted) -- launch program
            break
        end
    end
end

function M.insert_obsidian_excalidraw() insert_drawing(excalidraw) end
function M.insert_rnote() insert_drawing(rnote) end
function M.open_obsidian_excalidraw() open_drawing({ excalidraw }) end
function M.open_rnote() open_drawing({ rnote }) end
function M.open_drawing() open_drawing(providers) end

return M
