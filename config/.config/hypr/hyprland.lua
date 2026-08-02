-- Hyprland config.
-- Hyprland 0.55+ uses Lua; see https://wiki.hypr.land/Configuring/Start/
--
-- Layout: this file just wires up the modules in lua/. Each require() runs
-- in its own scope so an error in one file doesn't kill the others.

require("lua/monitors")
require("lua/autostart")
require("lua/look-and-feel")
require("lua/input")
require("lua/keybindings")
require("lua/windowrules")
