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

local function launch_excalidraw(path, _)
    print(string.format('Opening %s in Obsidian Excalidraw', path))
    utils.run_shell_command(
        string.format('%s "obsidian://open?path=%s"', config_excalidraw.uriOpenCommand, utils.urlencode(path)),
        false
    )
end

local watched = {}
local watched_count = 0

local function auto_export_rnote(path, path_export)
    if watched[path] ~= nil then
        watched[path].last_use = vim.uv.now() - 1000
        return
    end

    -- limit amount of watchers
    if watched_count >= config_rnote.maxWatchedFiles then
        local oldest, oldest_key = nil, nil
        for p, data in pairs(watched) do
            if oldest == nil or data.last_use < oldest then
                oldest, oldest_key = data.last_use, p
            end
        end
        if oldest_key ~= nil then
            watched[oldest_key].watcher:stop()
            watched[oldest_key] = nil
        end
        watched_count = watched_count - 1
    end

    -- setup watcher
    local job_id = -1
    watched_count = watched_count + 1
    watched[path] = {
        last_use = vim.uv.now() - 1000,
        watcher = vim.uv.new_fs_poll(),
    }
    local run_export = function(err)
        if err ~= nil then return end
        local time = vim.uv.now()
        if job_id == -1 and time - watched[path].last_use > 800 then
            watched[path].last_use = time
            local cmd = string.format(config_rnote.exportCommand, path_export, path, path_export, path)
            job_id = utils.run_shell_command(cmd, false, nil, { on_exit = function() job_id = -1 end })
        end
    end
    watched[path].watcher:start(path, 1500, vim.schedule_wrap(run_export))
end

local function launch_rnote(path, path_export)
    print(string.format('Opening %s in Rnote', path))
    utils.run_shell_command(string.format('%s %s', config_rnote.uriOpenCommand, path), false)
    auto_export_rnote(path, path_export)
end

local function insert_drawing(provider)
    local cfg = provider[1]
    local assets_dir = vim.fn.expand('%:p:h') .. '/' .. cfg.assetsDir
    local filename = os.date(cfg.filename)
    local path = assets_dir .. '/' .. filename .. cfg.fileExtension
    local path_export = assets_dir .. '/' .. filename .. cfg.fileExtensionInserted
    local path_insert = cfg.assetsDir .. '/' .. filename .. cfg.fileExtensionInserted -- local relative path

    if vim.fn.isdirectory(assets_dir) == 0 then vim.fn.mkdir(assets_dir, 'p') end
    local found_match = false
    for _, template_config in ipairs(cfg.templatePath) do
        local pattern = template_config[1]
        local template_path = template_config[2]
        if string.match(path, pattern) then
            found_match = true
            -- use cat as we don't want to copy file metadata
            utils.run_shell_command(string.format('cat %s > %s', template_path, path), false, nil, {
                on_exit = function()
                    -- insert text and launch program
                    utils.insert_text_block(string.format(provider[2], path_insert))
                    provider[3](path, path_export)
                end,
            })
            break
        end
    end
    if not found_match then
        print('No matching template found for path: ' .. path)
        return
    end
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
            local path_export = vim.fn.expand('%:p:h') .. '/' .. filename .. cfg.fileExtensionInserted
            provider[3](path, path_export) -- launch program
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
