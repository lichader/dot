return {
    "nvim-tree/nvim-tree.lua",
    -- lazy = true,
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        local nvimtree = require("nvim-tree")

        -- recommended settings from nvim-tree documentation
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        nvimtree.setup({
            open_on_tab = false,
            update_focused_file = {
                enable = true,
                update_cwd = true,
                ignore_list = {},
            },
            actions = {
                use_system_clipboard = true,
                open_file = {
                    quit_on_open = true,
                },
            },
            view = {
                adaptive_size = true,
            },
            filters = {
                custom = { ".DS_Store" },
            },
            git = {
                ignore = false,
            },
        })

        local map = vim.api.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        -- nvim tree
        map("n", "<C-n>", ":NvimTreeToggle<CR>", opts)
        map("n", "<C-g>", ":NvimTreeFindFile<CR>", opts)
    end,
}
