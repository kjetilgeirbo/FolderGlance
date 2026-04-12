import AppKit
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        statusBarController = StatusBarController(appState: AppState.shared)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        false
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        .terminateNow
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
