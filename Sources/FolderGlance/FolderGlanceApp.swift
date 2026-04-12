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
