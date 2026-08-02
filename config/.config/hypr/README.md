# Some software requires speical setting

## Intellij

Using intellij 2025.2 version, there are some issues with the class search screen so i have to revert back to xwayland.

To get scale working comfortably, I have to

1. Change the vm options

```
-Dsun.java2d.uiScale=1
-Dhidpi=true
```

2. Update the zoom in intellij to 150%

Hyprland scale is set to 1.25 and in my main 32inch 4k monitor.
