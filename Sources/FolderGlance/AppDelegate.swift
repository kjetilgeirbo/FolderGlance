import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    private var settingsWindow: NSWindow?
    private var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController(appState: AppState.shared)
    }

    func showSettings() {
        if settingsWindow == nil {
            let hostingController = NSHostingController(
                rootView: SettingsView(appState: AppState.shared)
            )
            let window = NSWindow(contentViewController: hostingController)
            window.title = "FolderGlance Settings"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 480, height: 520))
            window.center()
            settingsWindow = window
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
