-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- Maximize window
-- wezterm.on("gui-startup", function(cmd)
-- 	local tab, pane, window = mux.spawn_window(cmd or {})
-- 	window:gui_window():maximize()
-- end)

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- This is where you actually apply your config choices
--
config.initial_cols = 250
config.initial_rows = 80

-- For example, changing the color scheme:
config.color_scheme = "Gruvbox dark, pale (base16)"
-- config.color_scheme = "Catppuccin Latte"
config.color_schemes = {
    ["Gruvbox dark, pale (base16)"] = {
        background = "Black",
    },
}

config.font_size = 12
config.font = wezterm.font_with_fallback({
    { family = "JetBrainsMono Nerd Font" },
    { family = "Source Han Sans CN" },
    { family = "Noto Color Emoji" },
})
config.adjust_window_size_when_changing_font_size = false

config.enable_tab_bar = false
config.window_background_opacity = 0.85
config.hide_tab_bar_if_only_one_tab = false
config.macos_window_background_blur = 100
config.window_close_confirmation = "NeverPrompt"

config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}

-- NOTE: This is used for simulating navigating word by word in iterm2
config.keys = {
    { key = "LeftArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bb" }) },
    { key = "RightArrow", mods = "OPT", action = wezterm.action({ SendString = "\x1bf" }) },
    -- NOTE: Mostly for system that has multiple clipboard https://wezfurlong.org/wezterm/config/lua/keyassignment/PasteFrom.html
}

-- and finally, return the configuration to wezterm
return config
