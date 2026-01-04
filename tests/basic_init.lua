-- setup mini test environment
require('mini.test').setup()

-- properly source plugin when in dev shell
vim.opt.rtp:prepend(os.getenv('NVIM_PLUGIN_DEV') or '')

-- basic typstar setup
local ls = require('luasnip')
ls.config.set_config({
    enable_autosnippets = true,
    store_selection_keys = '<Tab>',
})

local typstar = require('typstar')
typstar.setup({
    anki = {
        typstarAnkiCmd = 'uv run typstar-anki',
    },
})

vim.g.mapleader = ' '
vim.keymap.set({ 'n', 'i' }, '<M-t>', '<Cmd>TypstarToggleSnippets<CR>', { silent = true, noremap = true })
vim.keymap.set({ 's', 'i' }, '<M-j>', '<Cmd>TypstarSmartJump<CR>', { silent = true, noremap = true })
vim.keymap.set({ 's', 'i' }, '<M-k>', '<Cmd>TypstarSmartJumpBack<CR>', { silent = true, noremap = true })

vim.keymap.set('n', '<leader>e', '<Cmd>TypstarInsertExcalidraw<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>r', '<Cmd>TypstarInsertRnote<CR>', { silent = true, noremap = true })
vim.keymap.set('n', '<leader>o', '<Cmd>TypstarOpenDrawing<CR>', { silent = true, noremap = true })

vim.keymap.set('n', '<leader>a', '<Cmd>TypstarAnkiScan<CR>', { silent = true, noremap = true })
