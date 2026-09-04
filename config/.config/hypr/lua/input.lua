-- Input devices + per-device overrides.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input

hl.config({
    input = {
        kb_layout    = "us",
        kb_variant   = "",
        kb_model     = "",
        kb_options   = "",
        kb_rules     = "",

        follow_mouse = 1,
        sensitivity  = 0,
        natural_scroll = false,

        touchpad = {
            natural_scroll = true,
        },
    },
})

-- Per-device input config.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

hl.device({
    name          = "logitech-mx-master-3s-for-mac",
    sensitivity   = -0.6,
    scroll_factor = 0.8,
})

hl.device({
    name          = "logitech-gaming-mouse-g502",
    sensitivity   = -0.6,
    scroll_factor = 1.2,
})
