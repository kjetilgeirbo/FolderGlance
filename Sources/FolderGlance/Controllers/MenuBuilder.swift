import AppKit
import ObjectiveC

private var delegateKey: UInt8 = 0

enum MenuBuilder {
    static func populate(
        menu: NSMenu,
        folderURL: URL,
        sortOrder: FolderSortOrder,
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
            let delegate = FolderMenuDelegate(
                folderURL: folderURL,
                sortOrder: sortOrder,
                sortAscending: sortAscending,
                showHidden: showHidden
            )
            objc_setAssociatedObject(submenu, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            submenu.delegate = delegate
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

        let quitItem = NSMenuItem(
            title: "Quit FolderGlance",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
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
                    let delegate = FolderMenuDelegate(
                        folderURL: url,
                        sortOrder: folder.sortOrder,
                        sortAscending: folder.sortAscending,
                        showHidden: showHidden
                    )
                    objc_setAssociatedObject(submenu, &delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                    submenu.delegate = delegate
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

        let quitItem = NSMenuItem(
            title: "Quit FolderGlance",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)
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

        let folders = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
        let files = contents.filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true }

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
        MenuBuilder.populate(
            menu: menu,
            folderURL: folderURL,
            sortOrder: sortOrder,
            sortAscending: sortAscending,
            showHidden: showHidden
        )
    }
}
