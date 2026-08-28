-- Keybindings + submaps.
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local progs = require("lua/programs")

local mod = "SUPER"
local modShift = "SUPER + SHIFT"
local modAlt = "SUPER + ALT"

----------------------------------------------------------------------
-- Open apps
----------------------------------------------------------------------
hl.bind(mod .. " + T", hl.dsp.exec_cmd(progs.terminal))
hl.bind(mod .. " + E", hl.dsp.exec_cmd(progs.file_manager))
hl.bind(mod .. " + B", hl.dsp.exec_cmd(progs.browser))
hl.bind(mod .. " + Y", hl.dsp.exec_cmd(progs.task_manager))
hl.bind(mod .. " + V", hl.dsp.exec_cmd("cliphist list | wofi -S dmenu | cliphist decode | wl-copy"))

hl.bind(modShift .. " + C", hl.dsp.window.close())
hl.bind(modShift .. " + F", hl.dsp.window.float({ action = "toggle" }))

-- 1 = maximize (vs full fullscreen)
hl.bind(modShift .. " + M", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(modShift .. " + N", hl.dsp.exec_cmd("wlogout"))

----------------------------------------------------------------------
-- Screenshots / overlay
----------------------------------------------------------------------
hl.bind(modShift .. " + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | swappy -f -'))
hl.bind(modShift .. " + A", hl.dsp.exec_cmd("grim - | swappy -f -"))
hl.bind(modShift .. " + D", hl.dsp.exec_cmd("pkill -SIGUSR1 wayscriber"))

----------------------------------------------------------------------
-- Quick web apps (Chrome PWA mode)
----------------------------------------------------------------------
hl.bind(modShift .. " + Q", hl.dsp.exec_cmd("google-chrome-stable --app=https://chatgpt.com/"))
hl.bind(modShift .. " + E", hl.dsp.exec_cmd("google-chrome-stable --app=https://www.reddit.com"))
hl.bind(modShift .. " + X", hl.dsp.exec_cmd("google-chrome-stable --app=https://x.com/home"))
hl.bind(modShift .. " + W", hl.dsp.exec_cmd("google-chrome-stable --app=https://excalidraw.com/"))
hl.bind(modShift .. " + O", hl.dsp.exec_cmd("google-chrome-stable --app=http://mynas.local:9070/unread"))
hl.bind(modShift .. " + Y", hl.dsp.exec_cmd("google-chrome-stable --app=https://www.youtube.com"))

----------------------------------------------------------------------
-- Groups
----------------------------------------------------------------------
hl.bind(modShift .. " + G", hl.dsp.group.toggle())
hl.bind(mod .. " + TAB", hl.dsp.group.next())
hl.bind(modAlt .. " + h", hl.dsp.window.move({ into_group = "l" }))
hl.bind(modAlt .. " + l", hl.dsp.window.move({ into_group = "r" }))
hl.bind(modAlt .. " + k", hl.dsp.window.move({ into_group = "u" }))
hl.bind(modAlt .. " + j", hl.dsp.window.move({ into_group = "d" }))

----------------------------------------------------------------------
-- Launcher / layout
----------------------------------------------------------------------
hl.bind(mod .. " + space", hl.dsp.exec_cmd(progs.menu))
hl.bind(mod .. " + P", hl.dsp.window.pseudo())

----------------------------------------------------------------------
-- Window movement
----------------------------------------------------------------------
hl.bind(modShift .. " + h", hl.dsp.window.swap({ direction = "l" }))
hl.bind(modShift .. " + l", hl.dsp.window.swap({ direction = "r" }))
hl.bind(modShift .. " + k", hl.dsp.window.swap({ direction = "u" }))
hl.bind(modShift .. " + j", hl.dsp.window.swap({ direction = "d" }))

-- Focus movement
hl.bind(mod .. " + h", hl.dsp.focus({ direction = "left" }))
hl.bind(mod .. " + l", hl.dsp.focus({ direction = "right" }))
hl.bind(mod .. " + k", hl.dsp.focus({ direction = "up" }))
hl.bind(mod .. " + j", hl.dsp.focus({ direction = "down" }))

----------------------------------------------------------------------
-- Workspaces (1-10) + move window to workspace
----------------------------------------------------------------------
for i = 1, 10 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(modShift .. " + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Scroll through workspaces
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move / resize with mouse drag
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

----------------------------------------------------------------------
-- Resize submap (vim keys)
----------------------------------------------------------------------
hl.bind(modShift .. " + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
	hl.bind("h", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
	hl.bind("l", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
	hl.bind("k", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
	hl.bind("j", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })
	hl.bind("escape", hl.dsp.submap("reset"))
end)

----------------------------------------------------------------------
-- Multimedia keys
-- bindel (locked + repeating) -> { locked = true, repeating = true }
-- bindl  (locked)             -> { locked = true }
----------------------------------------------------------------------
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh up"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh down"),
	{ locked = true, repeating = true }
)
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("~/.config/hypr/scripts/volume.sh mute"), { locked = true, repeating = true })
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 10%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 10%-"), { locked = true, repeating = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
