import Foundation

enum FolderSortOrder: String, Codable, CaseIterable {
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
    var sortOrder: FolderSortOrder
    var sortAscending: Bool
    var displayMode: DisplayMode
    var isEnabled: Bool

    init(
        id: UUID = UUID(),
        url: URL,
        displayName: String? = nil,
        icon: String = "folder",
        sortOrder: FolderSortOrder = .name,
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
