# FolderGlance

macOS menu bar app for quick folder access. Similar to Sindre Sorhus's Folder Peek.

## Tech Stack

- **Language:** Swift (SPM executable target, NOT Xcode project)
- **Menu bar:** AppKit `NSStatusItem` + `NSMenu` with `NSMenuDelegate` for lazy-loading submenus
- **Settings UI:** SwiftUI `SettingsView` hosted in `NSWindow` via `NSHostingController`
- **Persistence:** `UserDefaults` with `JSONEncoder`/`JSONDecoder`
- **Entry point:** `main.swift` (top-level code, not SwiftUI `@main`)
- **Minimum:** macOS 14.0+

## Architecture

```
main.swift                  → NSApplication.run() entry point
AppDelegate.swift           → Creates StatusBarController, manages Settings window
StatusBarController.swift   → Creates NSStatusItem(s), assigns NSMenu with delegates
MenuBuilder.swift           → Builds NSMenu content, lazy submenu loading via FolderMenuDelegate
MenuActionHandler.swift     → Singleton with @objc actions (openFile, revealInFinder, openSettings)
Models/AppState.swift       → ObservableObject singleton, @Published folders/settings, persists to UserDefaults
Models/FolderModel.swift    → Codable struct with URL, displayName, icon, sortOrder, displayMode
Views/SettingsView.swift    → SwiftUI settings: add/remove folders, per-folder config, general settings
```

## Key Design Decisions

- **AppKit NSMenu (not SwiftUI MenuBarExtra):** MenuBarExtra evaluates all view content synchronously, causing freezes on large directories. NSMenu with NSMenuDelegate.menuNeedsUpdate(_:) loads submenus lazily on hover.
- **objc_setAssociatedObject for delegates:** NSMenu.delegate is weak. FolderMenuDelegate must be retained via associated object on the menu.
- **skippedNames filter:** .build, .git, node_modules, DerivedData etc. are filtered from directory listings.
- **maxItemsPerLevel = 50:** Caps items per directory level with "Show All in Finder" overflow link.
- **Finder label colors:** Read via URLResourceKey.labelColorKey, rendered as colored dot on icon. Composite image with isTemplate = false.
- **LSUIElement = true:** App hidden from Dock and Cmd-Tab.

## Build & Run

```bash
# Debug (local dev)
swift build
cp .build/arm64-apple-macosx/debug/FolderGlance FolderGlance.app/Contents/MacOS/FolderGlance
codesign --force --sign - FolderGlance.app
open FolderGlance.app

# Release DMG (universal binary)
./scripts/build-release.sh 1.2.0
```

## .app Bundle

The `FolderGlance.app/` directory is a manually created bundle (not Xcode-generated). It contains:
- `Contents/Info.plist` — with LSUIElement, CFBundleIconFile
- `Contents/MacOS/FolderGlance` — copied from .build after swift build
- `Contents/Resources/AppIcon.icns` — app icon
- `Contents/Resources/MenuBarIcon.png` — transparent menu bar icon

The .app bundle is gitignored. The build script recreates it from scratch.

## Tests

```bash
swift test
```

7 tests: FolderModelTests (4) + AppStateTests (3). Uses injectable UserDefaults for isolation.

## Current Status (v1.1.0)

### Working
- Menu bar icon (custom transparent PNG) with dropdown menu
- Add/remove/configure folders via Settings
- Recursive lazy-loading submenus (hover to expand)
- Click to open file/folder, option-click to reveal in Finder
- Finder label colors on icons
- Separate icon per folder or grouped in one menu
- Sort by name/date modified/date created/size
- Noise directory filtering and max items cap
- Release build script with universal binary DMG
- GitHub releases at https://github.com/kjetilgeirbo/FolderGlance

### Known Limitations
- Ad-hoc signed only (no notarization — Gatekeeper will warn on first launch)
- Menu bar icon may not appear if menu bar is full (MacBook notch overflow)
- No launch-at-login yet
- No file type icons in menu (uses generic Finder icons via NSWorkspace)
