# FolderGlance MVP Design Spec

## Overview

FolderGlance is a macOS menu bar utility that provides quick access to folder contents directly from the menu bar. Targeted at developers who need fast access to project files.

**App name:** FolderGlance
**Location:** `~/Developer/FolderGlance/`
**Platform:** macOS 14+ (Sonoma)
**Tech:** Swift, AppKit (NSStatusItem + NSMenu), SwiftUI (Settings window)
**Pricing:** Free / personal use

## Architecture

### Approach: AppKit NSStatusItem + NSMenu with SwiftUI Settings

AppKit handles menu bar icons and dropdown menus. SwiftUI handles the settings window. This gives full control over menu behavior (modifier key detection, section headers, submenus) while keeping the settings UI modern and easy to build.

### Modules

| Module | Responsibility |
|--------|---------------|
| `FolderGlanceApp` | App entry point, lifecycle, creates StatusBarController |
| `StatusBarController` | Owns NSStatusItem instances, creates/removes them as folders change |
| `FolderModel` | Data model: folder URL, display mode, sort order, icon |
| `MenuBuilder` | Builds NSMenu from folder contents recursively |
| `SettingsView` | SwiftUI settings window for adding/removing/configuring folders |
| `AppState` | ObservableObject holding all folders and settings, persisted to UserDefaults |

### Flow

```
App start → AppState loads saved folders from UserDefaults
         → StatusBarController creates NSStatusItem per separate-mode folder
         → + one NSStatusItem for grouped menu (if any grouped folders exist)
         → Click → MenuBuilder reads folder contents → builds NSMenu
         → Normal click on file → NSWorkspace.open()
         → Option-click on file → NSWorkspace.activateFileViewerSelecting()
```

## Data Model

### FolderModel (Codable, Identifiable)

| Field | Type | Description |
|-------|------|-------------|
| `id` | UUID | Unique identifier |
| `url` | URL | Folder path, stored as security-scoped bookmark |
| `displayName` | String | Auto-detected from folder name, user-overridable |
| `icon` | String | SF Symbol name, default "folder" |
| `sortOrder` | SortOrder | .name, .dateModified, .dateCreated, .size |
| `sortAscending` | Bool | Sort direction |
| `displayMode` | DisplayMode | .separate (own menu bar icon) or .grouped (shared menu) |
| `isEnabled` | Bool | Toggle visibility without removing |

### AppState (ObservableObject)

| Field | Type | Description |
|-------|------|-------------|
| `folders` | [FolderModel] | All configured folders |
| `groupedMenuIcon` | String | SF Symbol for the grouped menu bar icon |
| `showHiddenFiles` | Bool | Whether to show dotfiles |

### Persistence

- `UserDefaults` with JSON-encoded AppState
- Folder URLs stored as security-scoped bookmarks via `URL.bookmarkData()` to retain access across app restarts

## Menu Structure

### Separate mode (one NSStatusItem per folder)

```
Folder Icon (NSMenu)
├── [folder icon] Subfolder       → submenu (recursive)
├── [folder icon] Subfolder 2     → submenu (recursive)
├── ─────────────── (separator)
├── [file icon] file.swift         → click: open / option-click: Finder
├── [file icon] README.md          → click: open / option-click: Finder
├── ─────────────── (separator)
└── Settings...                    → opens Settings window
```

### Grouped mode (one NSStatusItem for all grouped folders)

```
Grouped Icon (NSMenu)
├── 「Project A」                   (section title, disabled, bold)
│   ├── [folder] src               → submenu
│   └── [file] Package.swift
├── ─────────────── (separator)
├── 「Project B」
│   ├── [folder] lib               → submenu
│   └── [file] index.ts
├── ─────────────── (separator)
└── Settings...
```

## User Interaction

| Action | Result |
|--------|--------|
| Click file | `NSWorkspace.shared.open(url)` — opens in default app |
| Option-click file | `NSWorkspace.shared.activateFileViewerSelecting([url])` — reveal in Finder |
| Click folder | Opens submenu showing contents |
| Option-click folder | Opens folder in Finder |
| Click "Settings..." | Opens SwiftUI Settings window |

## Menu Building

- **Lazy loading:** Menu built on demand via `NSMenuDelegate.menuNeedsUpdate(_:)` — always fresh, no background watchers
- **Sort order:** Folders always first, then files sorted by configured sort order
- **Hidden files:** Filtered out unless `showHiddenFiles` is enabled
- **Modifier detection:** `NSEvent.modifierFlags.contains(.option)` checked in menu item action handler

## Settings Window (SwiftUI)

### Layout

- **Folder list:** All configured folders with display mode badge, edit and delete buttons
- **Add folder button:** Opens `NSOpenPanel` with `canChooseDirectories = true`
- **Per-folder settings (when selected):**
  - Display name (text field)
  - Icon (SF Symbol picker or text field)
  - Sort order (picker) with ascending/descending toggle
  - Display mode (separate / grouped radio)
- **General settings:**
  - Show hidden files (toggle)
  - Grouped menu icon (SF Symbol)
  - Launch at login (`SMAppService.mainApp`)

## File Icons

Use `NSWorkspace.shared.icon(forFile:)` to get the system icon for each file, scaled to menu item size (16pt). This gives native-looking file type icons without bundling any assets.

## Out of Scope for MVP

- Drag & drop from menus
- File preview within menus
- Global keyboard shortcuts
- Apple Shortcuts integration
- Image/video dimension display
- File size display
- Custom menu bar icon images (only SF Symbols)
- Alias/symlink following (beyond what FileManager does natively)

## Technical Notes

- **Minimum macOS:** 14.0 (Sonoma) — gives us MenuBarExtra fallback, SMAppService, modern SwiftUI
- **No sandbox:** For MVP, run without sandbox to simplify file access. Sandboxing can be added for App Store distribution later.
- **No notarization:** Developer-signed only for MVP
- **Security-scoped bookmarks:** Required even without sandbox for persistent URL access via NSOpenPanel
