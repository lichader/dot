return {
    "nvim-telescope/telescope.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        "nvim-tree/nvim-web-devicons",
        "folke/todo-comments.nvim",
    },
    config = function()
        local telescope = require("telescope")
        telescope.setup({
            defaults = {
                -- Default configuration for telescope goes here:
                -- config_key = value,
                mappings = {
                    i = {
                        -- map actions.which_key to <C-h> (default: <C-/>)
                        -- actions.which_key shows the mappings for your picker,
                        -- e.g. git_{create, delete, ...}_branch for the git_branches picker
                        ["<C-h>"] = "which_key",
                    },
                },
                file_ignore_patterns = { "node_modules/", ".git/", "lazy-lock.json" },
            },
            pickers = {
                find_files = {
                    -- This setting will also show the hidden git folder, which is not idea
                    hidden = true,
                },
            },
        })
        require("telescope").load_extension("fzf")

        local map = vim.api.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        -- telescope
        map("n", "<leader>ff", ":Telescope find_files<cr>", opts)
        map("n", "<leader>fh", ":Telescope search_history<cr>", opts)
        map("n", "<leader>fl", ":Telescope live_grep<cr>", opts)
        map("n", "<leader>fu", ":Telescope buffers<cr>", opts)
        map("n", "<leader>fr", ":Telescope treesitter<cr>", opts)
        map("n", "<leader>fg", ":Telescope git_branches<cr>", opts)
    end,
}
