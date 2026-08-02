return {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    version = "*",
    opts = {
        options = {
            numbers = "ordinal",
            diagnostics = "nvim_lsp",
            offsets = {
                {
                    filetype = "NvimTree",
                    text = "File Explorer",
                    text_align = "left",
                },
            },
            buffer_close_icon = "",
            close_icon = "",
            left_trunc_marker = "",
            right_trunc_marker = "",
        },
    },
}
