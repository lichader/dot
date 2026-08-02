return {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
        vim.cmd("let g:gruvbox_transparent_bg = 1")
        vim.cmd("autocmd VimEnter * hi Normal ctermbg=NONE guibg=NONE")
        vim.cmd("autocmd ColorScheme * highlight SignColumn guibg=NONE")
        vim.cmd("colorscheme gruvbox")
    end,
}
