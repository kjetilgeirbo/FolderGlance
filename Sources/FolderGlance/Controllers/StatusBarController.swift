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
