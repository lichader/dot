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

	-- Desktop shell / applets / daemons
	hl.exec_cmd("noctalia")
	hl.exec_cmd("dropbox")
	hl.exec_cmd("tailscale systray")
	hl.exec_cmd("dbus-update-activation-environment --systemd --all")
	-- wayscriber runs under systemd so `systemctl --user restart wayscriber` cleanly reloads it.
	-- Started explicitly here since this session doesn't reach graphical-session.target.
	hl.exec_cmd(
		"systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE && systemctl --user restart wayscriber"
	)

	-- Input method
	hl.exec_cmd("fcitx5 -d")

	-- Wi-Fi / keyring
	hl.exec_cmd("/usr/bin/gnome-keyring-daemon --start --components=secrets")

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
