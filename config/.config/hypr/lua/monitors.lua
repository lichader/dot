-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

-- Fallback rule for any monitor not matched below.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.5 })

-- Virtio GPU output used by the Arch test VM.
hl.monitor({ output = "Virtual-1", mode = "3840x2160@60", position = "0x0", scale = 1.5 })

hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = 1.25 })

-- HDMI-A-1 rotated 270 (transform=1 = 90deg), placed to the right of DP-1.
hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "auto", scale = 1.25, transform = 1 })
