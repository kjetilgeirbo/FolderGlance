import AppKit
import ObjectiveC

private var delegateKey: UInt8 = 0

private let maxItemsPerLevel = 50

private let skippedNames: Set<String> = [
    ".build", ".git", ".svn", ".hg",
    "node_modules", "Pods", "DerivedData",
    ".swiftpm", "__pycache__", ".Trash",
    ".DS_Store", "xcuserdata"
]

enum MenuBuilder {

    // MARK: - Top-level menu for a single "separate" folder

    static func populate(
        menu: NSMenu,
        folderURL: URL,
        sortOrder: FolderSortOrder,
        sortAscending: Bool,
        showHidden: Bool
    ) {
        menu.removeAllItems()

        addFolderContents(
            to: menu,
            folderURL: folderURL,
            sortOrder: sortOrder,
            sortAscending: sortAscending,
            showHidden: showHidden
        )

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
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
    }

    // MARK: - Grouped menu for multiple folders

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

            let header = NSMenuItem(title: folder.displayName, action: nil, keyEquivalent: "")
            header.attributedTitle = NSAttributedString(
                string: folder.displayName,
                attributes: [.font: NSFont.boldSystemFont(ofSize: 0)]
            )
            header.isEnabled = false
            menu.addItem(header)

            addFolderContents(
                to: menu,
                folderURL: folder.url,
                sortOrder: folder.sortOrder,
                sortAscending: folder.sortAscending,
                showHidden: showHidden,
                indentationLevel: 1
            )
        }

        menu.addItem(.separator())
        let settingsItem = NSMenuItem(
            title: "Settings\u{2026}",
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
    }

    // MARK: - Submenu-only content (no Settings/Quit)

    static func populateSubmenu(
        menu: NSMenu,
        folderURL: URL,
        sortOrder: FolderSortOrder,
        sortAscending: Bool,
        showHidden: Bool
    ) {
        menu.removeAllItems()
        addFolderContents(
            to: menu,
            folderURL: folderURL,
            sortOrder: sortOrder,
            sortAscending: sortAscending,
            showHidden: showHidden
        )

        if menu.items.isEmpty {
            let emptyItem = NSMenuItem(title: "(empty)", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        }
    }

    // MARK: - Icon with Finder label color

    private static func iconForURL(_ url: URL) -> NSImage {
        let baseIcon = NSWorkspace.shared.icon(forFile: url.path)
        baseIcon.size = NSSize(width: 16, height: 16)

        guard let values = try? url.resourceValues(forKeys: [.labelColorKey]),
              let labelColor = values.labelColor else {
            return baseIcon
        }

        let size = NSSize(width: 16, height: 16)
        let composite = NSImage(size: size, flipped: false) { rect in
            baseIcon.draw(in: rect)
            let dotSize: CGFloat = 7
            let dotRect = NSRect(
                x: rect.width - dotSize - 0.5,
                y: 0.5,
                width: dotSize,
                height: dotSize
            )
            // White outline for contrast
            NSColor.white.setFill()
            NSBezierPath(ovalIn: dotRect.insetBy(dx: -0.5, dy: -0.5)).fill()
            labelColor.setFill()
            NSBezierPath(ovalIn: dotRect).fill()
            return true
        }
        composite.isTemplate = false
        return composite
    }

    // MARK: - Shared content builder

    private static func addFolderContents(
        to menu: NSMenu,
        folderURL: URL,
        sortOrder: FolderSortOrder,
        sortAscending: Bool,
        showHidden: Bool,
        indentationLevel: Int = 0
    ) {
        let contents = directoryContents(
            at: folderURL,
            sortOrder: sortOrder,
            ascending: sortAscending,
            showHidden: showHidden
        )

        let capped = Array(contents.prefix(maxItemsPerLevel))
        let wasCapped = contents.count > maxItemsPerLevel

        let folders = capped.filter { $0.hasDirectoryPath }
        let files = capped.filter { !$0.hasDirectoryPath }

        // Folders first — each with a lazy submenu
        for url in folders {
            let name = url.lastPathComponent
            let item = NSMenuItem(title: name, action: nil, keyEquivalent: "")
            item.image = iconForURL(url)
            item.indentationLevel = indentationLevel

            let submenu = NSMenu(title: name)
            let delegate = FolderMenuDelegate(
                folderURL: url,
                sortOrder: sortOrder,
                sortAscending: sortAscending,
                showHidden: showHidden
            )
            objc_setAssociatedObject(submenu, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            submenu.delegate = delegate
            // Placeholder so macOS shows the submenu arrow
            submenu.addItem(NSMenuItem(title: "Loading\u{2026}", action: nil, keyEquivalent: ""))
            item.submenu = submenu

            menu.addItem(item)

            // Alternate: option-click opens folder in Finder
            let altItem = NSMenuItem(
                title: "Open \"\(name)\" in Finder",
                action: #selector(MenuActionHandler.openFolder(_:)),
                keyEquivalent: ""
            )
            altItem.representedObject = url
            altItem.target = MenuActionHandler.shared
            altItem.isAlternate = true
            altItem.keyEquivalentModifierMask = .option
            altItem.indentationLevel = indentationLevel
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
            item.image = iconForURL(fileURL)
            item.indentationLevel = indentationLevel
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
            altItem.indentationLevel = indentationLevel
            menu.addItem(altItem)
        }

        // "Show All in Finder" when items were capped
        if wasCapped {
            menu.addItem(.separator())
            let moreItem = NSMenuItem(
                title: "Show All in Finder (\(contents.count) items)",
                action: #selector(MenuActionHandler.openFolder(_:)),
                keyEquivalent: ""
            )
            moreItem.representedObject = folderURL
            moreItem.target = MenuActionHandler.shared
            moreItem.indentationLevel = indentationLevel
            menu.addItem(moreItem)
        }
    }

    // MARK: - Directory Reading

    static func directoryContents(
        at url: URL,
        sortOrder: FolderSortOrder,
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

        let filtered = contents.filter { !skippedNames.contains($0.lastPathComponent) }

        let folders = filtered.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
        let files = filtered.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }

        let sortedFolders = sort(urls: folders, by: sortOrder, ascending: ascending)
        let sortedFiles = sort(urls: files, by: sortOrder, ascending: ascending)

        return sortedFolders + sortedFiles
    }

    private static func sort(urls: [URL], by order: FolderSortOrder, ascending: Bool) -> [URL] {
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
    let sortOrder: FolderSortOrder
    let sortAscending: Bool
    let showHidden: Bool

    init(folderURL: URL, sortOrder: FolderSortOrder, sortAscending: Bool, showHidden: Bool) {
        self.folderURL = folderURL
        self.sortOrder = sortOrder
        self.sortAscending = sortAscending
        self.showHidden = showHidden
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        MenuBuilder.populateSubmenu(
            menu: menu,
            folderURL: folderURL,
            sortOrder: sortOrder,
            sortAscending: sortAscending,
            showHidden: showHidden
        )
    }
}
