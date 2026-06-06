/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_: Notification) {
        // Initialize Tuck Icons
        _ = TuckIcons.shared

        // If enabled hide menu bar icons at launch
        TuckIcons.shared.hideAtLaunch()

        _ = TuckIcons.toggleDockIcon(showIcon: false)
    }

    // Show all Tuck icons when opening Tuck from Finder etc.
    func applicationOpenUntitledFile(_ sender: NSApplication) -> Bool {
        TuckIcons.shared.showAll()
        return true
    }

    func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: General())
            window.title = "Tuck Settings"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.setContentSize(NSSize(width: 360, height: 210))
            window.center()
            settingsWindow = window
        }

        NSApp.setActivationPolicy(.regular)
        settingsWindow?.makeKeyAndOrderFront(nil)
        settingsWindow?.orderFrontRegardless()
        NSApp.activate()
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }
}
