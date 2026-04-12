import Testing
import Foundation
@testable import FolderGlance

@Suite("FolderModel Tests")
struct FolderModelTests {
    @Test("FolderSortOrder raw values round-trip through Codable")
    func sortOrderCodable() throws {
        for order in FolderSortOrder.allCases {
            let data = try JSONEncoder().encode(order)
            let decoded = try JSONDecoder().decode(FolderSortOrder.self, from: data)
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
