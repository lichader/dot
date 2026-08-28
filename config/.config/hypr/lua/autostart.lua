-- Env vars + processes launched on Hyprland start.
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

local progs = require("lua/programs")

-- Cursor sizes
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Desktop / session
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("GDK_BACKEND", "wayland")
hl.env("OZONE_PLATFORM", "wayland")

-- Qt theming
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_STYLE_OVERRIDE", "kvantum")

hl.env("EDITOR", "nvim")

hl.on("hyprland.start", function()
	-- xdg-desktop-portal expects graphical-session.target to be active, but this
	-- session does not reach it by itself. Start a Hyprland-specific target so
	-- screen sharing services bind to a real graphical session.
	local hyprland_session_target = table.concat({
		"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP HYPRLAND_INSTANCE_SIGNATURE",
		"systemctl --user start hyprland-session.target",
		"systemctl --user restart xdg-desktop-portal",
	}, " && ")
	hl.exec_cmd(hyprland_session_target)

	-- Bars / applets / daemons
	hl.exec_cmd("waybar")
	hl.exec_cmd("nm-applet")
	hl.exec_cmd("blueman-applet")
	hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
	hl.exec_cmd("dropbox")
	-- hypridle runs under systemd so `systemctl --user restart hypridle` cleanly reloads config.
	-- This session doesn't reach graphical-session.target, so start it explicitly here after
	-- importing WAYLAND_DISPLAY (the unit has ConditionEnvironment=WAYLAND_DISPLAY).
	hl.exec_cmd(
		"systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE && systemctl --user restart hypridle"
	)
	hl.exec_cmd("hyprpaper")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	-- wayscriber runs under systemd so `systemctl --user restart wayscriber` cleanly reloads it.
	-- Started explicitly here since this session doesn't reach graphical-session.target.
	hl.exec_cmd(
		"systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE && systemctl --user restart wayscriber"
	)

	-- Input method
	hl.exec_cmd("fcitx5 -d")

	-- Clipboard history
	hl.exec_cmd("wl-paste --type text  --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")

	-- Wi-Fi / keyring
	hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=secrets")

	-- Monitor fix script
	hl.exec_cmd("~/.config/hypr/scripts/monitor-fix.sh")

	-- Apps pinned to workspaces.
	-- The "[workspace N silent]" prefix is parsed by Hyprland as a rule for the
	-- launched window, identical to the old hyprlang syntax.
	hl.exec_cmd("[workspace 1 silent] " .. progs.browser)
	hl.exec_cmd("[workspace 2 silent] ghostty -e herdr")
	hl.exec_cmd("[workspace 5 silent] steam")
	hl.exec_cmd("[workspace 6 silent] " .. progs.task_manager)

	hl.exec_cmd(
		"obsidian --enable-features=UseOzonePlatform,WaylandWindowDecorations --ozone-platform=wayland --enable-wayland-ime"
	)
	hl.exec_cmd("Telegram")
	hl.exec_cmd("spotify")
end)
