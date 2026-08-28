-- General / decoration / group / animations / layouts / misc / xwayland.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
	xwayland = {
		force_zero_scaling = true,
	},

	general = {
		gaps_in = 5,
		gaps_out = 5,
		border_size = 2,

		col = {
			active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			inactive_border = "rgba(595959aa)",
		},

		resize_on_border = false,
		allow_tearing = false,
		layout = "dwindle",
	},

	decoration = {
		rounding = 30,

		active_opacity = 0.98,
		inactive_opacity = 0.98,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = "rgba(1a1a1aee)",
		},

		blur = {
			enabled = true,
			size = 6,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = false,
			xray = false,
			noise = 0.0117,
			contrast = 0.8,
			brightness = 0.85,
			vibrancy = 0.25,
			vibrancy_darkness = 0.5,
		},
	},

	group = {
		col = {
			border_active = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
			border_inactive = "rgba(595959aa)",
			border_locked_active = "rgba(ff0000dd)",
			border_locked_inactive = "rgba(ff000055)",
		},

		groupbar = {
			enabled = true,
			font_family = "Sans",
			font_size = 16,
			height = 20,
			render_titles = true,
			scrolling = true,
			text_color = "rgba(33ccffff)",
			text_color_inactive = "rgba(ffffffff)",
			col = {
				active = "rgba(444444ff)",
				inactive = "rgba(111111ee)",
				locked_active = "rgba(ff0000dd)",
				locked_inactive = "rgba(77000055)",
			},
			gradients = true,
		},
	},

	animations = {
		enabled = true,
	},

	dwindle = {
		-- `pseudotile` is no longer a global switch in 0.55+; toggle per-window
		-- via the `mod + P` keybind (hl.dsp.window.pseudo()).
		preserve_split = true,
		-- prefer opening the new window on the right
		force_split = 2,
	},

	master = {
		new_status = "master",
	},

	misc = {
		force_default_wallpaper = -1,
		disable_hyprland_logo = true,
		focus_on_activate = true,
	},
})

-- Bezier curves.
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

-- Animation tree.
hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
