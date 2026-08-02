return {
    "someone-stole-my-name/yaml-companion.nvim",
    dependencies = {
        "neovim/nvim-lspconfig",
        "nvim-lua/plenary.nvim",
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("telescope").load_extension("yaml_schema")
        local map = vim.api.nvim_set_keymap
        local opts = { noremap = true, silent = true }

        -- register shortcut
        map("n", "<leader>fy", ":Telescope yaml_schema<cr>", opts)
    end,
}
