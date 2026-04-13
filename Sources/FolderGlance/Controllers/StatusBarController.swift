import AppKit
import Combine

class StatusBarController {
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    private var separateItems: [UUID: NSStatusItem] = [:]
    private var separateDelegates: [UUID: FolderMenuDelegate] = [:]
    private var groupedItem: NSStatusItem?
    private var groupedDelegate: GroupedMenuDelegate?

    private func menuBarIcon() -> NSImage? {
        guard let icon = Bundle.main.image(forResource: "MenuBarIcon") else {
            return Bundle.main.image(forResource: "AppIcon")
        }
        let size = NSSize(width: 18, height: 18)
        let resized = NSImage(size: size, flipped: false) { rect in
            icon.draw(in: rect)
            return true
        }
        resized.isTemplate = false
        return resized
    }

    init(appState: AppState) {
        self.appState = appState

        // Subscribe to future changes (skip initial value with dropFirst)
        appState.$folders
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildStatusItems() }
            .store(in: &cancellables)

        appState.$showHiddenFiles
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildStatusItems() }
            .store(in: &cancellables)

        appState.$groupedMenuIcon
            .dropFirst()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.updateGroupedIcon() }
            .store(in: &cancellables)

        // Build initial status items immediately
        rebuildStatusItems()
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
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.button?.image = menuBarIcon()
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
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.button?.image = menuBarIcon()
            statusItem.button?.toolTip = "FolderGlance"

            let menu = NSMenu()
            let delegate = GroupedMenuDelegate(appState: appState)
            menu.delegate = delegate
            statusItem.menu = menu

            groupedItem = statusItem
            groupedDelegate = delegate
        }

        // If no status items exist, show a default FolderGlance icon for settings access
        if separateItems.isEmpty && groupedItem == nil {
            let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            statusItem.button?.image = menuBarIcon()
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
    }

    private func updateGroupedIcon() {
        groupedItem?.button?.image = menuBarIcon()
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
