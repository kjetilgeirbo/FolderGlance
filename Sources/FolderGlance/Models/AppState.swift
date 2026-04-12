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
