# FolderGlance MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS menu bar app that provides quick access to folder contents directly from the menu bar, targeted at developers.

**Architecture:** Swift Package Manager executable. AppKit NSStatusItem + NSMenu for menu bar icons and dropdowns. SwiftUI Settings scene for the preferences window. Combine for reactive updates from AppState to StatusBarController. Single-module package with test target importing the executable.

**Tech Stack:** Swift 6.2, macOS 14+ (Sonoma), AppKit, SwiftUI, Combine, SPM

---

## File Structure

```
FolderGlance/
├── Package.swift
├── .gitignore
├── Sources/FolderGlance/
│   ├── FolderGlanceApp.swift          # @main App struct + Settings scene
│   ├── AppDelegate.swift              # NSApplicationDelegateAdaptor, lifecycle
│   ├── Models/
│   │   ├── FolderModel.swift          # FolderModel, SortOrder, DisplayMode
│   │   └── AppState.swift             # @Published folders, JSON persistence
│   ├── Controllers/
│   │   ├── StatusBarController.swift  # Manages NSStatusItem instances
│   │   ├── MenuBuilder.swift          # Populates NSMenu from directory
│   │   └── MenuActionHandler.swift    # Singleton target for menu actions
│   └── Views/
│       └── SettingsView.swift         # Folder list, per-folder config, general
├── Tests/FolderGlanceTests/
│   ├── FolderModelTests.swift
│   └── AppStateTests.swift
└── docs/superpowers/
    ├── specs/2026-04-13-folderglance-mvp-design.md
    └── plans/2026-04-13-folderglance-mvp.md
```

---

### Task 1: Project Scaffolding

**Files:**
- Create: `Package.swift`
- Create: `.gitignore`
- Create: `Sources/FolderGlance/FolderGlanceApp.swift`
- Create: `Sources/FolderGlance/AppDelegate.swift`
- Create: `Sources/FolderGlance/Models/` (empty dir placeholder)
- Create: `Sources/FolderGlance/Controllers/` (empty dir placeholder)
- Create: `Sources/FolderGlance/Views/` (empty dir placeholder)

- [ ] **Step 1: Create Package.swift**

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FolderGlance",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FolderGlance",
            path: "Sources/FolderGlance"
        ),
        .testTarget(
            name: "FolderGlanceTests",
            dependencies: ["FolderGlance"],
            path: "Tests/FolderGlanceTests"
        ),
    ]
)
```

- [ ] **Step 2: Create .gitignore**

```
.DS_Store
/.build
/Packages
xcuserdata/
DerivedData/
.swiftpm/xcode/package.xcworkspace/contents.xcworkspacedata
.swiftpm/xcode/xcuserdata
```

- [ ] **Step 3: Create minimal FolderGlanceApp.swift**

```swift
import SwiftUI

@main
struct FolderGlanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            Text("FolderGlance Settings — coming soon")
                .frame(width: 400, height: 300)
        }
    }
}
```

- [ ] **Step 4: Create minimal AppDelegate.swift**

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
```

- [ ] **Step 5: Build and verify**

Run: `cd ~/Developer/FolderGlance && swift build 2>&1`
Expected: Build succeeds with no errors.

Run: `swift run FolderGlance &; sleep 2; kill %1 2>/dev/null`
Expected: Process starts, no dock icon appears, exits cleanly.

- [ ] **Step 6: Commit**

```bash
cd ~/Developer/FolderGlance
git add Package.swift .gitignore Sources/
git commit -m "feat: scaffold FolderGlance macOS menu bar app

SPM executable with SwiftUI App lifecycle and AppKit delegate.
Activation policy set to .accessory (no dock icon)."
```

---

### Task 2: Data Models

**Files:**
- Create: `Sources/FolderGlance/Models/FolderModel.swift`
- Create: `Tests/FolderGlanceTests/FolderModelTests.swift`

- [ ] **Step 1: Write FolderModel tests**

```swift
import Testing
import Foundation
@testable import FolderGlance

@Suite("FolderModel Tests")
struct FolderModelTests {
    @Test("SortOrder raw values round-trip through Codable")
    func sortOrderCodable() throws {
        for order in SortOrder.allCases {
            let data = try JSONEncoder().encode(order)
            let decoded = try JSONDecoder().decode(SortOrder.self, from: data)
            #expect(decoded == order)
        }
    }

    @Test("DisplayMode raw values round-trip through Codable")
    func displayModeCodable() throws {
        for mode in DisplayMode.allCases {
            let data = try JSONEncoder().encode(mode)
            let decoded = try JSONDecoder().decode(DisplayMode.self, from: data)
            #expect(decoded == mode)
        }
    }

    @Test("FolderModel round-trips through JSON")
    func folderModelCodable() throws {
        let model = FolderModel(
            url: URL(fileURLWithPath: "/tmp/test"),
            displayName: "Test Folder",
            icon: "folder.fill",
            sortOrder: .dateModified,
            sortAscending: false,
            displayMode: .grouped,
            isEnabled: true
        )
        let data = try JSONEncoder().encode(model)
        let decoded = try JSONDecoder().decode(FolderModel.self, from: data)
        #expect(decoded.id == model.id)
        #expect(decoded.url == model.url)
        #expect(decoded.displayName == model.displayName)
        #expect(decoded.icon == model.icon)
        #expect(decoded.sortOrder == .dateModified)
        #expect(decoded.sortAscending == false)
        #expect(decoded.displayMode == .grouped)
        #expect(decoded.isEnabled == true)
    }

    @Test("FolderModel default values are sensible")
    func folderModelDefaults() {
        let model = FolderModel(url: URL(fileURLWithPath: "/Users/test/Projects"))
        #expect(model.displayName == "Projects")
        #expect(model.icon == "folder")
        #expect(model.sortOrder == .name)
        #expect(model.sortAscending == true)
        #expect(model.displayMode == .separate)
        #expect(model.isEnabled == true)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd ~/Developer/FolderGlance && swift test 2>&1`
Expected: Compilation errors — `SortOrder`, `DisplayMode`, `FolderModel` not defined.

- [ ] **Step 3: Implement FolderModel.swift**

```swift
import Foundation

enum SortOrder: String, Codable, CaseIterable {
    case name
    case dateModified
    case dateCreated
    case size
}

enum DisplayMode: String, Codable, CaseIterable {
    case separate
    case grouped
}

struct FolderModel: Codable, Identifiable {
    let id: UUID
    var url: URL
    var displayName: String
    var icon: String
    var sortOrder: SortOrder
    var sortAscending: Bool
    var displayMode: DisplayMode
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        displayName: String? = nil,
        icon: String = "folder",
        sortOrder: SortOrder = .name,
        sortAscending: Bool = true,
        displayMode: DisplayMode = .separate,
        isEnabled: Bool = true
    ) {
        self.id = id
        self.url = url
        self.displayName = displayName ?? url.lastPathComponent
        self.icon = icon
        self.sortOrder = sortOrder
        self.sortAscending = sortAscending
        self.displayMode = displayMode
        self.isEnabled = isEnabled
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/Developer/FolderGlance && swift test 2>&1`
Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
cd ~/Developer/FolderGlance
git add Sources/FolderGlance/Models/FolderModel.swift Tests/
git commit -m "feat: add FolderModel with SortOrder and DisplayMode

Codable struct with sensible defaults. Display name auto-detected
from folder URL last path component."
```

---

### Task 3: AppState with Persistence

**Files:**
- Create: `Sources/FolderGlance/Models/AppState.swift`
- Create: `Tests/FolderGlanceTests/AppStateTests.swift`

- [ ] **Step 1: Write AppState tests**

```swift
import Testing
import Foundation
@testable import FolderGlance

@Suite("AppState Tests")
struct AppStateTests {
    @Test("Save and load round-trips folders through UserDefaults")
    func saveLoadRoundTrip() {
        let defaults = UserDefaults(suiteName: "test.FolderGlance.\(UUID().uuidString)")!
        let state = AppState(defaults: defaults)

        let folder = FolderModel(
            url: URL(fileURLWithPath: "/tmp/test-project"),
            displayName: "Test Project",
            sortOrder: .dateModified,
            displayMode: .grouped
        )
        state.folders.append(folder)
        state.showHiddenFiles = true
        state.groupedMenuIcon = "tray.full"
        state.save()

        let loaded = AppState(defaults: defaults)
        loaded.load()
        #expect(loaded.folders.count == 1)
        #expect(loaded.folders[0].displayName == "Test Project")
        #expect(loaded.folders[0].sortOrder == .dateModified)
        #expect(loaded.folders[0].displayMode == .grouped)
        #expect(loaded.showHiddenFiles == true)
        #expect(loaded.groupedMenuIcon == "tray.full")

        defaults.removePersistentDomain(forName: defaults.suiteName ?? "")
    }

    @Test("Load with empty defaults produces empty state")
    func loadEmpty() {
        let defaults = UserDefaults(suiteName: "test.FolderGlance.\(UUID().uuidString)")!
        let state = AppState(defaults: defaults)
        state.load()
        #expect(state.folders.isEmpty)
        #expect(state.showHiddenFiles == false)
        #expect(state.groupedMenuIcon == "tray.2.fill")

        defaults.removePersistentDomain(forName: defaults.suiteName ?? "")
    }

    @Test("Adding and removing folders works")
    func addRemoveFolders() {
        let defaults = UserDefaults(suiteName: "test.FolderGlance.\(UUID().uuidString)")!
        let state = AppState(defaults: defaults)

        let folder1 = FolderModel(url: URL(fileURLWithPath: "/tmp/a"))
        let folder2 = FolderModel(url: URL(fileURLWithPath: "/tmp/b"))
        state.folders.append(folder1)
        state.folders.append(folder2)
        #expect(state.folders.count == 2)

        state.folders.removeAll { $0.id == folder1.id }
        #expect(state.folders.count == 1)
        #expect(state.folders[0].id == folder2.id)

        defaults.removePersistentDomain(forName: defaults.suiteName ?? "")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd ~/Developer/FolderGlance && swift test 2>&1`
Expected: Compilation error — `AppState` not defined.

- [ ] **Step 3: Implement AppState.swift**

```swift
import Foundation
import Combine

class AppState: ObservableObject {
    static let shared = AppState()

    @Published var folders: [FolderModel] = []
    @Published var showHiddenFiles: Bool = false
    @Published var groupedMenuIcon: String = "tray.2.fill"

    private let defaults: UserDefaults
    private static let foldersKey = "FolderGlance.folders"
    private static let showHiddenKey = "FolderGlance.showHiddenFiles"
    private static let groupedIconKey = "FolderGlance.groupedMenuIcon"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        load()
    }

    func save() {
        if let data = try? JSONEncoder().encode(folders) {
            defaults.set(data, forKey: Self.foldersKey)
        }
        defaults.set(showHiddenFiles, forKey: Self.showHiddenKey)
        defaults.set(groupedMenuIcon, forKey: Self.groupedIconKey)
    }

    func load() {
        if let data = defaults.data(forKey: Self.foldersKey),
           let decoded = try? JSONDecoder().decode([FolderModel].self, from: data) {
            folders = decoded
        }
        showHiddenFiles = defaults.bool(forKey: Self.showHiddenKey)
        if let icon = defaults.string(forKey: Self.groupedIconKey), !icon.isEmpty {
            groupedMenuIcon = icon
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd ~/Developer/FolderGlance && swift test 2>&1`
Expected: All tests pass (FolderModel + AppState tests).

- [ ] **Step 5: Commit**

```bash
cd ~/Developer/FolderGlance
git add Sources/FolderGlance/Models/AppState.swift Tests/FolderGlanceTests/AppStateTests.swift
git commit -m "feat: add AppState with JSON persistence to UserDefaults

Shared singleton, injectable defaults for testing.
Stores folders, showHiddenFiles, groupedMenuIcon."
```

---

### Task 4: MenuBuilder and MenuActionHandler

**Files:**
- Create: `Sources/FolderGlance/Controllers/MenuActionHandler.swift`
- Create: `Sources/FolderGlance/Controllers/MenuBuilder.swift`

- [ ] **Step 1: Implement MenuActionHandler.swift**

```swift
import AppKit

class MenuActionHandler: NSObject {
    static let shared = MenuActionHandler()

    @objc func openFile(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func revealInFinder(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    @objc func openFolder(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc func openSettings(_ sender: NSMenuItem) {
        NSApp.activate()
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
}
```

- [ ] **Step 2: Implement MenuBuilder.swift**

```swift
import AppKit

enum MenuBuilder {
    static func populate(
        menu: NSMenu,
        folderURL: URL,
        sortOrder: SortOrder,
        sortAscending: Bool,
        showHidden: Bool
    ) {
        menu.removeAllItems()

        let contents = directoryContents(
            at: folderURL,
            sortOrder: sortOrder,
            ascending: sortAscending,
            showHidden: showHidden
        )

        let folders = contents.filter { $0.hasDirectoryPath }
        let files = contents.filter { !$0.hasDirectoryPath }

        // Folders first — each with a submenu
        for folderURL in folders {
            let name = folderURL.lastPathComponent
            let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            item.image = NSWorkspace.shared.icon(forFile: folderURL.path)
            item.image?.size = NSSize(width: 16, height: 16)

            let submenu = NSMenu(title: name)
            submenu.delegate = FolderMenuDelegate(
                folderURL: folderURL,
                sortOrder: sortOrder,
                sortAscending: sortAscending,
                showHidden: showHidden
            )
            // Add a placeholder so the submenu arrow appears
            submenu.addItem(NSMenuItem(title: "Loading…", action: nil, keyEquivalent: ""))
            item.submenu = submenu

            menu.addItem(item)

            // Alternate: option-click opens folder in Finder
            let altItem = NSMenuItem(
                title: "Open \"\(name)\" in Finder",
                action: #selector(MenuActionHandler.openFolder(_:)),
                keyEquivalent: ""
            )
            altItem.representedObject = folderURL
            altItem.target = MenuActionHandler.shared
            altItem.isAlternate = true
            altItem.keyEquivalentModifierMask = .option
            menu.addItem(altItem)
        }

        if !folders.isEmpty && !files.isEmpty {
            menu.addItem(.separator())
        }

        // Files
        for fileURL in files {
            let name = fileURL.lastPathComponent
            let item = NSMenuItem(
                title: name,
                action: #selector(MenuActionHandler.openFile(_:)),
                keyEquivalent: ""
            )
            item.representedObject = fileURL
            item.target = MenuActionHandler.shared
            item.image = NSWorkspace.shared.icon(forFile: fileURL.path)
            item.image?.size = NSSize(width: 16, height: 16)
            menu.addItem(item)

            // Alternate: option-click reveals in Finder
            let altItem = NSMenuItem(
                title: "Reveal \"\(name)\" in Finder",
                action: #selector(MenuActionHandler.revealInFinder(_:)),
                keyEquivalent: ""
            )
            altItem.representedObject = fileURL
            altItem.target = MenuActionHandler.shared
            altItem.isAlternate = true
            altItem.keyEquivalentModifierMask = .option
            menu.addItem(altItem)
        }

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(MenuActionHandler.openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = MenuActionHandler.shared
        menu.addItem(settingsItem)
    }

    static func populateGrouped(
        menu: NSMenu,
        folders: [FolderModel],
        showHidden: Bool
    ) {
        menu.removeAllItems()

        let enabledGrouped = folders.filter { $0.isEnabled && $0.displayMode == .grouped }
        for (index, folder) in enabledGrouped.enumerated() {
            if index > 0 {
                menu.addItem(.separator())
            }
            // Section header
            let header = NSMenuItem(title: folder.displayName, action: nil, keyEquivalent: "")
            header.attributedTitle = NSAttributedString(
                string: folder.displayName,
                attributes: [.font: NSFont.boldSystemFont(ofSize: 0)]
            )
            header.isEnabled = false
            menu.addItem(header)

            let contents = directoryContents(
                at: folder.url,
                sortOrder: folder.sortOrder,
                ascending: folder.sortAscending,
                showHidden: showHidden
            )

            for url in contents {
                if url.hasDirectoryPath {
                    let name = url.lastPathComponent
                    let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
                    item.image = NSWorkspace.shared.icon(forFile: url.path)
                    item.image?.size = NSSize(width: 16, height: 16)
                    item.indentationLevel = 1

                    let submenu = NSMenu(title: name)
                    submenu.delegate = FolderMenuDelegate(
                        folderURL: url,
                        sortOrder: folder.sortOrder,
                        sortAscending: folder.sortAscending,
                        showHidden: showHidden
                    )
                    submenu.addItem(NSMenuItem(title: "Loading…", action: nil, keyEquivalent: ""))
                    item.submenu = submenu
                    menu.addItem(item)

                    let altItem = NSMenuItem(
                        title: "Open \"\(name)\" in Finder",
                        action: #selector(MenuActionHandler.openFolder(_:)),
                        keyEquivalent: ""
                    )
                    altItem.representedObject = url
                    altItem.target = MenuActionHandler.shared
                    altItem.isAlternate = true
                    altItem.keyEquivalentModifierMask = .option
                    altItem.indentationLevel = 1
                    menu.addItem(altItem)
                } else {
                    let name = url.lastPathComponent
                    let item = NSMenuItem(
                        title: name,
                        action: #selector(MenuActionHandler.openFile(_:)),
                        keyEquivalent: ""
                    )
                    item.representedObject = url
                    item.target = MenuActionHandler.shared
                    item.image = NSWorkspace.shared.icon(forFile: url.path)
                    item.image?.size = NSSize(width: 16, height: 16)
                    item.indentationLevel = 1
                    menu.addItem(item)

                    let altItem = NSMenuItem(
                        title: "Reveal \"\(name)\" in Finder",
                        action: #selector(MenuActionHandler.revealInFinder(_:)),
                        keyEquivalent: ""
                    )
                    altItem.representedObject = url
                    altItem.target = MenuActionHandler.shared
                    altItem.isAlternate = true
                    altItem.keyEquivalentModifierMask = .option
                    altItem.indentationLevel = 1
                    menu.addItem(altItem)
                }
            }
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(MenuActionHandler.openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = MenuActionHandler.shared
        menu.addItem(settingsItem)
    }

    // MARK: - Directory Reading

    static func directoryContents(
        at url: URL,
        sortOrder: SortOrder,
        ascending: Bool,
        showHidden: Bool
    ) -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey, .creationDateKey, .fileSizeKey],
            options: showHidden ? [] : [.skipsHiddenFiles]
        ) else {
            return []
        }

        let folders = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
        let files = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }

        let sortedFolders = sort(urls: folders, by: sortOrder, ascending: ascending)
        let sortedFiles = sort(urls: files, by: sortOrder, ascending: ascending)

        return sortedFolders + sortedFiles
    }

    private static func sort(urls: [URL], by order: SortOrder, ascending: Bool) -> [URL] {
        let sorted = urls.sorted { a, b in
            switch order {
            case .name:
                return a.lastPathComponent.localizedStandardCompare(b.lastPathComponent) == .orderedAscending
            case .dateModified:
                let dateA = (try? a.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
                return dateA < dateB
            case .dateCreated:
                let dateA = (try? a.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let dateB = (try? b.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return dateA < dateB
            case .size:
                let sizeA = (try? a.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                let sizeB = (try? b.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                return sizeA < sizeB
            }
        }
        return ascending ? sorted : sorted.reversed()
    }
}

// MARK: - NSMenuDelegate for lazy submenu loading

class FolderMenuDelegate: NSObject, NSMenuDelegate {
    let folderURL: URL
    let sortOrder: SortOrder
    let sortAscending: Bool
    let showHidden: Bool

    init(folderURL: URL, sortOrder: SortOrder, sortAscending: Bool, showHidden: Bool) {
        self.folderURL = folderURL
        self.sortOrder = sortOrder
        self.sortAscending = sortAscending
        self.showHidden = showHidden
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        MenuBuilder.populate(
            menu: menu,
            folderURL: folderURL,
            sortOrder: sortOrder,
            sortAscending: sortAscending,
            showHidden: showHidden
        )
    }
}
```

- [ ] **Step 3: Build to verify compilation**

Run: `cd ~/Developer/FolderGlance && swift build 2>&1`
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/FolderGlance
git add Sources/FolderGlance/Controllers/
git commit -m "feat: add MenuBuilder and MenuActionHandler

Recursive menu building from directory contents.
Folders first with submenus, files with open/reveal actions.
Option-click alternate items via NSMenuItem.isAlternate.
Grouped menu mode with bold section headers.
Lazy submenu loading via FolderMenuDelegate."
```

---

### Task 5: StatusBarController

**Files:**
- Create: `Sources/FolderGlance/Controllers/StatusBarController.swift`
- Modify: `Sources/FolderGlance/AppDelegate.swift`

- [ ] **Step 1: Implement StatusBarController.swift**

```swift
import AppKit
import Combine

class StatusBarController {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    private var separateItems: [UUID: NSStatusItem] = [:]
    private var separateDelegates: [UUID: FolderMenuDelegate] = [:]
    private var groupedItem: NSStatusItem?
    private var groupedDelegate: GroupedMenuDelegate?

    init(appState: AppState) {
        self.appState = appState

        appState.$folders
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildStatusItems() }
            .store(in: &cancellables)

        appState.$showHiddenFiles
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildStatusItems() }
            .store(in: &cancellables)

        appState.$groupedMenuIcon
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateGroupedIcon() }
            .store(in: &cancellables)
    }

    func rebuildStatusItems() {
        // Remove all existing items
        for (_, item) in separateItems {
            NSStatusBar.system.removeStatusItem(item)
        }
        separateItems.removeAll()
        separateDelegates.removeAll()

        if let grouped = groupedItem {
            NSStatusBar.system.removeStatusItem(grouped)
            groupedItem = nil
            groupedDelegate = nil
        }

        let enabledFolders = appState.folders.filter { $0.isEnabled }

        // Create separate items
        for folder in enabledFolders where folder.displayMode == .separate {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem.button?.image = NSImage(systemSymbolName: folder.icon, accessibilityDescription: folder.displayName)
            statusItem.button?.toolTip = folder.displayName

            let menu = NSMenu()
            let delegate = FolderMenuDelegate(
                folderURL: folder.url,
                sortOrder: folder.sortOrder,
                sortAscending: folder.sortAscending,
                showHidden: appState.showHiddenFiles
            )
            menu.delegate = delegate
            statusItem.menu = menu

            separateItems[folder.id] = statusItem
            separateDelegates[folder.id] = delegate
        }

        // Create grouped item if any grouped folders exist
        let groupedFolders = enabledFolders.filter { $0.displayMode == .grouped }
        if !groupedFolders.isEmpty {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
            statusItem.button?.image = NSImage(
                systemSymbolName: appState.groupedMenuIcon,
                accessibilityDescription: "FolderGlance"
            )
            statusItem.button?.toolTip = "FolderGlance"

            let menu = NSMenu()
            let delegate = GroupedMenuDelegate(appState: appState)
            menu.delegate = delegate
            statusItem.menu = menu

            groupedItem = statusItem
            groupedDelegate = delegate
        }
    }

    private func updateGroupedIcon() {
        groupedItem?.button?.image = NSImage(
            systemSymbolName: appState.groupedMenuIcon,
            accessibilityDescription: "FolderGlance"
        )
    }
}

// MARK: - Grouped menu delegate

class GroupedMenuDelegate: NSObject, NSMenuDelegate {
    let appState: AppState

    init(appState: AppState) {
        self.appState = appState
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        MenuBuilder.populateGrouped(
            menu: menu,
            folders: appState.folders,
            showHidden: appState.showHiddenFiles
        )
    }
}
```

- [ ] **Step 2: Update AppDelegate to create StatusBarController**

Replace `AppDelegate.swift` with:

```swift
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(appState: AppState.shared)
    }
}
```

- [ ] **Step 3: Build and run manually**

Run: `cd ~/Developer/FolderGlance && swift build 2>&1`
Expected: Build succeeds.

To test manually: `swift run FolderGlance` — no menu bar icons yet (no folders configured), but Settings... would be accessible once we add a default icon.

- [ ] **Step 4: Commit**

```bash
cd ~/Developer/FolderGlance
git add Sources/FolderGlance/Controllers/StatusBarController.swift Sources/FolderGlance/AppDelegate.swift
git commit -m "feat: add StatusBarController managing NSStatusItems

Reactively creates/removes status items via Combine.
Separate mode: one icon per folder. Grouped mode: shared icon.
GroupedMenuDelegate for combined folder menu."
```

---

### Task 6: Settings View

**Files:**
- Create: `Sources/FolderGlance/Views/SettingsView.swift`
- Modify: `Sources/FolderGlance/FolderGlanceApp.swift`

- [ ] **Step 1: Implement SettingsView.swift**

```swift
import SwiftUI
import AppKit

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @State private var selectedFolderID: UUID?

    var body: some View {
        VStack(spacing: 0) {
            folderListSection
            Divider()
            if let id = selectedFolderID,
               let index = appState.folders.firstIndex(where: { $0.id == id }) {
                folderSettingsSection(index: index)
            } else {
                Text("Select a folder to configure")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            Divider()
            generalSettingsSection
        }
        .frame(width: 480, height: 520)
    }

    // MARK: - Folder List

    private var folderListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Folders")
                .font(.headline)

            List(selection: $selectedFolderID) {
                ForEach(appState.folders) { folder in
                    HStack {
                        Image(systemName: folder.icon)
                            .frame(width: 20)
                        VStack(alignment: .leading) {
                            Text(folder.displayName)
                            Text(folder.url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Text(folder.displayMode == .separate ? "separate" : "grouped")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.quaternary)
                            .clipShape(Capsule())
                        Toggle("", isOn: Binding(
                            get: { folder.isEnabled },
                            set: { newValue in
                                if let i = appState.folders.firstIndex(where: { $0.id == folder.id }) {
                                    appState.folders[i].isEnabled = newValue
                                    appState.save()
                                }
                            }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    .tag(folder.id)
                }
                .onDelete(perform: deleteFolders)
            }
            .frame(height: 160)

            HStack {
                Button("Add Folder…") { addFolder() }
                Spacer()
                Button(role: .destructive) {
                    if let id = selectedFolderID {
                        appState.folders.removeAll { $0.id == id }
                        selectedFolderID = nil
                        appState.save()
                    }
                } label: {
                    Image(systemName: "trash")
                }
                .disabled(selectedFolderID == nil)
            }
        }
        .padding()
    }

    // MARK: - Per-Folder Settings

    private func folderSettingsSection(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Folder Settings")
                .font(.headline)

            LabeledContent("Display Name") {
                TextField("Name", text: $appState.folders[index].displayName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: appState.folders[index].displayName) { appState.save() }
            }

            LabeledContent("Icon (SF Symbol)") {
                TextField("folder", text: $appState.folders[index].icon)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: appState.folders[index].icon) { appState.save() }
            }

            LabeledContent("Sort By") {
                HStack {
                    Picker("", selection: $appState.folders[index].sortOrder) {
                        Text("Name").tag(SortOrder.name)
                        Text("Date Modified").tag(SortOrder.dateModified)
                        Text("Date Created").tag(SortOrder.dateCreated)
                        Text("Size").tag(SortOrder.size)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .onChange(of: appState.folders[index].sortOrder) { appState.save() }

                    Button {
                        appState.folders[index].sortAscending.toggle()
                        appState.save()
                    } label: {
                        Image(systemName: appState.folders[index].sortAscending ? "arrow.up" : "arrow.down")
                    }
                }
            }

            LabeledContent("Display Mode") {
                Picker("", selection: $appState.folders[index].displayMode) {
                    Text("Separate icon").tag(DisplayMode.separate)
                    Text("Grouped menu").tag(DisplayMode.grouped)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
                .onChange(of: appState.folders[index].displayMode) { appState.save() }
            }
        }
        .padding()
    }

    // MARK: - General Settings

    private var generalSettingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.headline)

            Toggle("Show hidden files", isOn: $appState.showHiddenFiles)
                .onChange(of: appState.showHiddenFiles) { appState.save() }

            LabeledContent("Grouped menu icon") {
                TextField("tray.2.fill", text: $appState.groupedMenuIcon)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
                    .onChange(of: appState.groupedMenuIcon) { appState.save() }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose a folder to add to FolderGlance"

        if panel.runModal() == .OK, let url = panel.url {
            let folder = FolderModel(url: url)
            appState.folders.append(folder)
            appState.save()
            selectedFolderID = folder.id
        }
    }

    private func deleteFolders(at offsets: IndexSet) {
        appState.folders.remove(atOffsets: offsets)
        appState.save()
    }
}
```

- [ ] **Step 2: Update FolderGlanceApp.swift to wire up SettingsView**

Replace `FolderGlanceApp.swift` with:

```swift
import SwiftUI

@main
struct FolderGlanceApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(appState: AppState.shared)
        }
    }
}
```

- [ ] **Step 3: Build and test manually**

Run: `cd ~/Developer/FolderGlance && swift build 2>&1`
Expected: Build succeeds.

Manual test: `swift run FolderGlance`
- No dock icon should appear
- If no folders configured, no menu bar icons appear
- Open Settings via adding a temporary test icon, or add a default "gear" icon in StatusBarController for when no folders are configured

- [ ] **Step 4: Add a fallback settings-only status item when no folders are configured**

Add to the end of `StatusBarController.rebuildStatusItems()`, before the closing brace:

```swift
// If no status items exist, show a default FolderGlance icon for settings access
if separateItems.isEmpty && groupedItem == nil {
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    statusItem.button?.image = NSImage(
        systemSymbolName: "folder.badge.gearshape",
        accessibilityDescription: "FolderGlance"
    )
    statusItem.button?.toolTip = "FolderGlance — add folders in Settings"

    let menu = NSMenu()
    let settingsItem = NSMenuItem(
        title: "Settings…",
        action: #selector(MenuActionHandler.openSettings(_:)),
        keyEquivalent: ","
    )
    settingsItem.target = MenuActionHandler.shared
    menu.addItem(settingsItem)

    let quitItem = NSMenuItem(
        title: "Quit FolderGlance",
        action: #selector(NSApplication.terminate(_:)),
        keyEquivalent: "q"
    )
    menu.addItem(quitItem)

    statusItem.menu = menu
    groupedItem = statusItem
}
```

- [ ] **Step 5: Add Quit item to all menus**

In `MenuBuilder.populate()`, after the Settings item at the bottom, add:

```swift
let quitItem = NSMenuItem(
    title: "Quit FolderGlance",
    action: #selector(NSApplication.terminate(_:)),
    keyEquivalent: "q"
)
menu.addItem(quitItem)
```

Add the same two lines at the end of `MenuBuilder.populateGrouped()` after the Settings item.

- [ ] **Step 6: Build and verify**

Run: `cd ~/Developer/FolderGlance && swift build 2>&1`
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```bash
cd ~/Developer/FolderGlance
git add Sources/FolderGlance/Views/SettingsView.swift Sources/FolderGlance/FolderGlanceApp.swift Sources/FolderGlance/Controllers/StatusBarController.swift Sources/FolderGlance/Controllers/MenuBuilder.swift
git commit -m "feat: add SwiftUI settings view and wire up full app

Folder list with add/remove, per-folder config (name, icon, sort,
display mode), general settings (hidden files, grouped icon).
Fallback gear icon when no folders configured. Quit menu item."
```

---

### Task 7: Integration Verification

- [ ] **Step 1: Run all tests**

Run: `cd ~/Developer/FolderGlance && swift test 2>&1`
Expected: All tests pass.

- [ ] **Step 2: Manual end-to-end test**

Run: `cd ~/Developer/FolderGlance && swift run FolderGlance`

Test checklist:
1. App starts, no dock icon, gear icon in menu bar
2. Click gear → Settings... → Settings window opens
3. Add a folder (e.g. ~/Developer/FolderGlance itself)
4. Folder appears in menu bar with folder icon
5. Click icon → see folder contents with file icons
6. Click a file → opens in default app
7. Hold Option → see "Reveal in Finder" alternate items
8. Option-click a file → reveals in Finder
9. Subfolders show as expandable submenus
10. Change display mode to "grouped" → icon moves to grouped menu
11. Add second folder as grouped → both appear in grouped menu with headers
12. Toggle "Show hidden files" → .gitignore etc appear/disappear
13. Change sort order → menu contents reorder
14. Disable a folder → its icon disappears
15. Quit FolderGlance via menu → app exits

- [ ] **Step 3: Final commit**

```bash
cd ~/Developer/FolderGlance
git add -A
git commit -m "chore: add implementation plan

docs/superpowers/plans/2026-04-13-folderglance-mvp.md"
```
