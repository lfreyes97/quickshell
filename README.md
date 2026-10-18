# QuickShell Config

A Wayland desktop shell built with [QuickShell](https://quickshell.outfoxxed.me), featuring a GNOME/Adwaita-inspired design for Hyprland.

## Features

- **Bar** with activities, overview, clock, tray, and quick settings
- **Theme** system that follows GNOME color-scheme and accent-color via gsettings
- **Notifications** with toasts and dismiss support
- **Popups**: calendar, wallpaper picker, window controls, alt-tab, overview
- **Blur/transparency** controlled via alpha values in `Theme.qml`

## Requirements

- [QuickShell](https://quickshell.outfoxxed.me)
- Hyprland (for layer blur rules)
- gsettings (for live theme syncing)

## Install

Copy or symlink to `~/.config/quickshell`:

```bash
ln -s /path/to/this/repo ~/.config/quickshell
```

## Structure

```
shell.qml          # Entry point
Theme.qml          # Singleton – colors, fonts, layout tokens
PopupManager.qml   # Singleton – popup state
Notifications.qml  # Singleton – notification state
Switcher.qml       # Singleton – app switcher state
qmldir             # Module definition
components/
  Bar.qml          # Main panel
  ClockWidget.qml  # Clock display
  Tray.qml         # System tray
  Workspaces.qml   # Workspace indicators
  ...              # (28 components)
```

## Customization

Edit `Theme.qml` to adjust:
- `barAlpha` / `popupAlpha` – transparency levels
- `barHeight`, `radius`, `iconSize` – layout tokens
- `accentName` – accent color (blue, teal, green, etc.)

## Design

See [`DESIGN.md`](DESIGN.md) for the design policy: tokens, components, states, motion, icons and copy guidelines.
