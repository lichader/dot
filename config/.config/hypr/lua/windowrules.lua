-- Window + workspace rules.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- Rules are evaluated top to bottom; later matches override earlier ones.

----------------------------------------------------------------------
-- Workspace -> monitor pinning
----------------------------------------------------------------------
hl.workspace_rule({ workspace = "1", monitor = "DP-1" })
hl.workspace_rule({ workspace = "2", monitor = "DP-1" })
hl.workspace_rule({ workspace = "3", monitor = "DP-1" })
hl.workspace_rule({ workspace = "4", monitor = "DP-1" })
hl.workspace_rule({ workspace = "5", monitor = "DP-1" })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-1" })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1" })

----------------------------------------------------------------------
-- App -> workspace assignment
----------------------------------------------------------------------
hl.window_rule({ match = { class = "^(jetbrains-idea)$" }, workspace = "3", opacity = "0.95" })

hl.window_rule({ match = { class = "^(com.mitchellh.ghostty)" }, opacity = "0.95" })

-- Gaming
hl.window_rule({ match = { class = "^(steam)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^(heroic)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^(lutris)$" }, workspace = "5" })
hl.window_rule({ match = { class = "^(com.vysp3r.ProtonPlus)$" }, workspace = "5" })

-- Comms / notes
hl.window_rule({ match = { class = "(?i)slack" }, workspace = "6" })
hl.window_rule({ match = { class = "^(md.obsidian.Obsidian)$" }, workspace = "7" })

hl.window_rule({ match = { class = "^(discord)$" }, workspace = "8" })
hl.window_rule({ match = { class = "^(org.telegram.desktop)$" }, workspace = "8" })
hl.window_rule({ match = { class = "(?i)spotify" }, workspace = "8" })
hl.window_rule({ match = { class = "(?i)wechat" }, workspace = "8" })

-- Chrome PWAs on workspace 9
hl.window_rule({ match = { class = "^(chrome-www.reddit.com__-Default)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^(chrome-x.com__home-Default)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^(chrome-instapaper.com__u-Default)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^(chrome-www.xiaohongshu.com__explore-Default)$" }, workspace = "9" })
hl.window_rule({ match = { class = "^(chrome-www.youtube.com__-Default)$" }, workspace = "9" })

----------------------------------------------------------------------
-- XWayland dragging fix: ignore focus on empty-class, empty-title floats.
----------------------------------------------------------------------
hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
	},
	no_focus = true,
})

-- Keep the Obsidian web clipper able to surface the window.
hl.window_rule({ match = { class = "^(md.obsidian.Obsidian)$" }, focus_on_activate = true })

----------------------------------------------------------------------
-- Floating windows
----------------------------------------------------------------------
hl.window_rule({
	name = "Battle Net",
	match = { class = "^steam_app_default$", title = "^Battle.net$" },
	float = true,
})

hl.window_rule({ match = { class = "^mpv$" }, float = true })

-- WeChat main window (xwayland, empty class)
hl.window_rule({ match = { title = "^WeChat$", xwayland = true }, float = true })

-- WeChat Photos and Videos window
hl.window_rule({ match = { class = "^(wechat)$", title = "^(Photos and Videos)$" }, float = true })

-- File managers
hl.window_rule({ match = { class = "^(thunar)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$" }, float = true })

-- GNOME Calculator
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })

hl.window_rule({ match = { class = "^(Fladder)$" }, float = true })

hl.window_rule({ match = { class = "^(org.telegram.desktop)$", title = "^(Media viewer)" }, float = true })

----------------------------------------------------------------------
-- Picture-in-Picture: top-right corner, pinned across workspaces.
----------------------------------------------------------------------
hl.window_rule({
	name = "PIP window",
	match = { title = "^([Pp]icture[-\\s]?[Ii]n[-\\s]?[Pp]icture)(.*)$" },

	float = true,
	pin = true,
	no_initial_focus = true,
	size = { "monitor_w*0.25", "monitor_h*0.25" },
	move = { "monitor_w*0.74", "monitor_h*0.09" },
})

-- Google Meet PIP - bottom right corner
hl.window_rule({
	name = "Google Meet PIP Bottom right corner",
	match = { class = "^(google-chrome)$", title = "^Meet - .*$" },

	float = true,
	pin = true,
	no_initial_focus = true,
	size = { "monitor_w*0.2", "monitor_h*0.4" },
	move = { "monitor_w*0.78", "monitor_h*0.58" },
})
