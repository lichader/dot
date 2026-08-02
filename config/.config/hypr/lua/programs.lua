-- Programs used in keybindings and autostart.
return {
    terminal     = "ghostty",
    file_manager = "ghostty -e yazi",
    menu         = "wofi --show drun wofi --style ~/.config/wofi/style.css",
    browser      = "google-chrome-stable",
    task_manager = "ghostty -e btop",
}
