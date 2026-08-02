return {
    "folke/trouble.nvim",
    opts = {},
    cmd = "Trouble",
    keys = {
        {
            "<leader>xd",
            "<cmd>Trouble diagnostics toggle<cr>",
            desc = "Diagnostics (Trouble)",
        },
        {
            "<leader>xD",
            "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
            desc = "Buffer Diagnostics (Trouble)",
        },
        {
            "<leader>xs",
            "<cmd>Trouble symbols toggle focus=true<cr>",
            desc = "Symbols (Trouble)",
        },
        {
            "<leader>cl",
            "<cmd>Trouble lsp toggle focus=true win.position=right<cr>",
            desc = "LSP Definitions / references / ... (Trouble)",
        },
        {
            "<leader>xL",
            "<cmd>Trouble loclist toggle<cr>",
            desc = "Location List (Trouble)",
        },
        {
            "<leader>xQ",
            "<cmd>Trouble qflist toggle<cr>",
            desc = "Quickfix List (Trouble)",
        },
    },
    config = function()
        require("trouble").setup()
        -- Define custom highlight groups with transparent background and custom text color for trouble.nvim
        vim.api.nvim_set_hl(0, "TroubleNormal", { fg = "#c0c0c0", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TroubleNormalNC", { fg = "#c0c0c0", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TroubleText", { fg = "#ff0000", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TroubleCount", { fg = "#ffffff", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TroubleFile", { fg = "#0087d7", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TroubleFoldIcon", { fg = "#87d7ff", bg = "NONE" })
        vim.api.nvim_set_hl(0, "TroubleIndent", { fg = "#444444", bg = "NONE" })
    end,
}
