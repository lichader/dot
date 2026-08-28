-- Source: paulbkim-dev/vim-herdr-navigation, editor/nvim.lua
-- Herdr handles the direct Ctrl+h/j/k/l bindings. Neovim moves within its
-- own splits first, then hands an edge movement back to the surrounding pane.

local function navigate(window_command, direction)
    local previous_window = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. window_command)

    if vim.api.nvim_get_current_win() ~= previous_window then
        return
    end

    if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
        local herdr = vim.env.HERDR_BIN_PATH
        if not herdr or herdr == "" then
            herdr = "herdr"
        end

        vim.fn.system({
            herdr,
            "pane",
            "focus",
            "--direction",
            direction,
            "--pane",
            vim.env.HERDR_PANE_ID,
        })
    end
end

local function map(key, window_command, direction)
    vim.keymap.set("n", key, function()
        navigate(window_command, direction)
    end, {
        silent = true,
        noremap = true,
        desc = "Navigate " .. direction .. " (vim/herdr)",
    })
end

map("<C-h>", "h", "left")
map("<C-j>", "j", "down")
map("<C-k>", "k", "up")
map("<C-l>", "l", "right")
