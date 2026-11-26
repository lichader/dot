-- Window + workspace rules.
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- Rules are evaluated top to bottom; later matches override earlier ones.

----------------------------------------------------------------------
-- Workspace -> monitor pinning
----------------------------------------------------------------------
hl.workspace_rule({ workspace = "1", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "DP-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "HDMI-A-1", persistent = true })

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

-- JetBrains IDEs (native Wayland) re-request focus for an open modal dialog
-- whenever the main window gets focus. With the global focus_on_activate and
-- cursor warps that becomes a focus loop that traps the cursor in the dialog.
hl.window_rule({ match = { class = "^(jetbrains-.*)$" }, focus_on_activate = false })

----------------------------------------------------------------------
-- Floating windows
----------------------------------------------------------------------
hl.window_rule({
	name = "Noctalia Settings",
	match = { class = "dev.noctalia.Noctalia" },
	float = true,
	size = { 1080, 920 },
})

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
hl.window_rule({ match = { class = "^(org.gnome.Nautilus)$" }, float = true })
hl.window_rule({ match = { class = "^(thunar)$" }, float = true })
hl.window_rule({ match = { class = "^(org.kde.dolphin)$" }, float = true })

-- GNOME Calculator
hl.window_rule({ match = { class = "^(org.gnome.Calculator)$" }, float = true })

hl.window_rule({ match = { class = "^(Fladder)$" }, float = true })

hl.window_rule({ match = { class = "^(org.telegram.desktop)$", title = "^(Media viewer)" }, float = true })

-- Android Emulator (xwayland). Matched on class so the main window, its side
-- toolbar and Extended Controls all float, whatever title they have at map time.
hl.window_rule({ match = { class = "^(Emulator)$", xwayland = true }, float = true })

-- The emulator opens its toolbar and Extended Controls a moment after the main
-- window, so they land on whichever workspace is active by then. Move them to
-- the workspace of the main window ("Android Emulator - <avd>:<port>") from the
-- same process, so each emulator keeps its own windows together.
hl.on("window.open", function(window)
	if not window or window.class ~= "Emulator" or (window.title or ""):find("^Android Emulator") then
		return
	end

	for _, main in ipairs(hl.get_windows({ class = "Emulator" })) do
		if main.pid == window.pid and (main.title or ""):find("^Android Emulator") then
			local target = main.workspace
			local current = window.workspace
			if target and not target.special and (not current or current.id ~= target.id) then
				hl.dispatch(hl.dsp.window.move({
					workspace = target.id,
					follow = false,
					window = "address:" .. window.address,
				}))
			end
			return
		end
	end
end)

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

----------------------------------------------------------------------
-- Noctalia shell surfaces
----------------------------------------------------------------------
hl.layer_rule({
	name = "noctalia",
	match = {
		namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$",
	},
	no_anim = true,
	ignore_alpha = 0.5,
	blur = true,
	blur_popups = true,
})
