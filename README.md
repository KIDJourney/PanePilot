<p align="center">
  <img src="Resources/AppIcon.png" width="144" alt="PanePilot app icon">
</p>

<p align="center">
  English | <a href="README.zh-CN.md">简体中文</a>
</p>

# PanePilot

Arrange macOS windows from the keyboard and keep your hands in the work.

PanePilot is a lightweight menu bar utility for Apple Silicon Macs. It moves the focused window into halves, corners, thirds, displays, or a centered layout with global shortcuts. It also keeps an undo and redo history when a layout needs one more pass.

[Download the latest signed release](https://github.com/KIDJourney/PanePilot/releases/latest) | macOS 14 or later | Apple Silicon

## When PanePilot Helps

### Code beside the result

Put an editor on the left and a browser, simulator, or terminal on the right. Switch either window to a corner when you need a third reference without dragging borders.

### Research without losing context

Keep notes in one half while moving source material through the other half or the next third. Center a document when it becomes the only thing that matters.

### Present across displays

Send the focused window to the next or previous display while preserving its relative size and position. PanePilot uses each display's visible workspace, including the menu bar and Dock boundaries.

### Explore layouts freely

Grow, shrink, or cycle through thirds, then use Undo and Redo to move through recent PanePilot arrangements without reconstructing them by hand.

## Quick Start

1. Download the latest DMG from [GitHub Releases](https://github.com/KIDJourney/PanePilot/releases/latest).
2. Drag PanePilot to Applications and open it.
3. Grant PanePilot access in System Settings > Privacy & Security > Accessibility.
4. Use the PanePilot icon in the menu bar or press a global shortcut.

To keep PanePilot ready after every restart, open **Settings...** and enable **Launch at Login**. If macOS asks for approval, PanePilot links directly to the Login Items settings.

PanePilot checks GitHub Releases once each day at noon while it is running. When a newer signed release is available, it asks before downloading, validating, and installing the update. You can also choose **Check for Updates...** from the menu bar at any time.

Public releases are signed with a Developer ID certificate, notarized by Apple, and stapled before upload.

## Layouts And Shortcuts

| Task | Action | Default shortcut |
| --- | --- | --- |
| Focus | Center | Option-Command-C |
| Focus | Maximize | Option-Command-F |
| Split | Left / Right Half | Option-Command-Left / Right |
| Split | Top / Bottom Half | Option-Command-Up / Down |
| Tile | Upper Left / Right | Control-Command-Left / Right |
| Tile | Lower Left / Right | Control-Shift-Command-Left / Right |
| Cycle | Next / Previous Third | Control-Option-Right / Left |
| Resize | Make Larger / Smaller | Control-Option-Shift-Right / Left |
| Displays | Next / Previous Display | Control-Option-Command-Right / Left |
| History | Undo / Redo | Option-Command-Z / Option-Shift-Command-Z |

Open the menu bar icon and choose **Settings...** to launch PanePilot at login, record a different shortcut, disable one action, or restore every default. Changes take effect immediately. While a shortcut field is recording, PanePilot pauses its global shortcuts so the window under your cursor stays put.

## Privacy And Permissions

PanePilot does not require an account. Window management and settings stay local; the daily update check connects only to the PanePilot GitHub Releases API and downloads an update only after you approve it. macOS Accessibility permission is required because arranging another app's focused window uses the system Accessibility API.

## Build From Source

PanePilot is a Swift 6.2 package targeting macOS 14 and later.

```sh
swift build
swift test
make validate-docs
make install-hooks
make local-check
make verify-hotkey-dispatch
make verify-shortcut-recording
make verify-window-move
make verify-update-helper
make package
open dist/PanePilot.app
```

The desktop automation checks require an unlocked Mac with an active user session. `make install-hooks` enables the repository's local pre-commit build, test, and package gate. `make package` creates an ad-hoc signed development artifact; public GitHub Releases are also built, Developer ID signed, notarized, and verified entirely on the local Mac before upload, as documented in [AGENTS.md](AGENTS.md). GitHub Actions is not used.

## Acknowledgements

- [Spectacle](https://github.com/eczarny/spectacle) established the direct, keyboard-first workflow that inspired PanePilot.
- [Rectangle](https://github.com/rxhanson/Rectangle) carries that open-source macOS window-management tradition forward and informed the modern platform baseline.
