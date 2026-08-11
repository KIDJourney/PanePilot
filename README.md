# PanePilot

PanePilot is a modern Swift rewrite of the core Spectacle workflow: move and resize the focused macOS window with global keyboard shortcuts.

## Research snapshot

As of 2026-08-10:

- `eczarny/spectacle` is archived and read-only. GitHub shows it was archived on 2023-01-21, and its README says the project is not actively maintained.
- Spectacle's own README points users toward Rectangle as an open-source alternative.
- The original project is Objective-C and uses Carthage. PanePilot starts fresh in Swift 6.2 with a small Swift Package layout.
- Rectangle is the practical modern successor today: its site describes macOS shortcut and snap-area support, and states macOS 10.15+, Intel, and Apple Silicon support.
- A keyboard window manager still needs macOS Accessibility permission because it controls other apps' windows through the Accessibility API.

Sources:

- https://github.com/eczarny/spectacle
- https://rectangleapp.com/
- https://ryanhanson.dev/posts/switchToRectangle
- https://developer.apple.com/documentation/applicationservices/axuielement_h
- https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution

## Implemented

- Menu bar app, no Dock icon.
- Accessibility permission prompt and System Settings shortcut.
- Global hotkeys using Carbon `RegisterEventHotKey`.
- Focused-window movement via `AXUIElement`.
- Layouts: center, maximize, halves, corners, thirds, grow, shrink.
- Multi-display move preserving relative position.
- Undo and redo history for moved windows.
- `.app` bundle script with ad-hoc signing for local CI artifacts.
- Developer ID signing, notarization, stapling, DMG packaging, and GitHub Release upload for public releases.
- Pure layout tests.

## Shortcuts

| Action | Shortcut |
| --- | --- |
| Center | Option-Command-C |
| Maximize | Option-Command-F |
| Left Half | Option-Command-Left |
| Right Half | Option-Command-Right |
| Top Half | Option-Command-Up |
| Bottom Half | Option-Command-Down |
| Upper Left | Control-Command-Left |
| Lower Left | Control-Shift-Command-Left |
| Upper Right | Control-Command-Right |
| Lower Right | Control-Shift-Command-Right |
| Next Third | Control-Option-Right |
| Previous Third | Control-Option-Left |
| Make Larger | Control-Option-Shift-Right |
| Make Smaller | Control-Option-Shift-Left |
| Next Display | Control-Option-Command-Right |
| Previous Display | Control-Option-Command-Left |
| Undo | Option-Command-Z |
| Redo | Option-Shift-Command-Z |

## Build

```sh
swift build
swift test
make validate-docs
make app
make package
open dist/PanePilot.app
```

On first launch, grant PanePilot permission in System Settings -> Privacy & Security -> Accessibility.

## Release notes

`Scripts/build-app.sh` creates an ad-hoc signed app for local testing and CI artifacts.

Every push or pull request to `main` runs GitHub Actions CI on `macos-26`, validates docs, builds, tests, packages `PanePilot.app`, and uploads the zip as a workflow artifact. These artifacts are not public distribution builds.

Create a signed and notarized GitHub Release locally:

```sh
make release-tag TAG=v0.1.1
make verify-release TAG=v0.1.1
make launch-release TAG=v0.1.1
```

The release script uses a Developer ID Application certificate, submits the app and DMG to Apple notarization, staples both, validates Gatekeeper, then uploads `PanePilot-vX.Y.Z.dmg` and its sha256 to GitHub Releases.

## Name candidates

- PanePilot
- Framewise
- Snapline
- WindowWing
- Gridmark
- QuartzSnap
- PaneForge
- Dockless
- FramePilot
- TidyPane
