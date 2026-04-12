import Testing
import Foundation
@testable import FolderGlance

@Suite("AppState Tests")
struct AppStateTests {
    @Test("Save and load round-trips folders through UserDefaults")
    func saveLoadRoundTrip() {
        let suiteName = "test.FolderGlance.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
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

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Load with empty defaults produces empty state")
    func loadEmpty() {
        let suiteName = "test.FolderGlance.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let state = AppState(defaults: defaults)
        state.load()
        #expect(state.folders.isEmpty)
        #expect(state.showHiddenFiles == false)
        #expect(state.groupedMenuIcon == "tray.2.fill")

        defaults.removePersistentDomain(forName: suiteName)
    }

    @Test("Adding and removing folders works")
    func addRemoveFolders() {
        let suiteName = "test.FolderGlance.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        let state = AppState(defaults: defaults)

        let folder1 = FolderModel(url: URL(fileURLWithPath: "/tmp/a"))
        let folder2 = FolderModel(url: URL(fileURLWithPath: "/tmp/b"))
        state.folders.append(folder1)
        state.folders.append(folder2)
        #expect(state.folders.count == 2)

        state.folders.removeAll { $0.id == folder1.id }
        #expect(state.folders.count == 1)
        #expect(state.folders[0].id == folder2.id)

        defaults.removePersistentDomain(forName: suiteName)
    }
}
