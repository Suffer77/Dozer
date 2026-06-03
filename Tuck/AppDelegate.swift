/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import KeyboardShortcuts
import Settings

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_: Notification) {
        KeyboardShortcuts.onKeyDown(for: .toggleMenuItems) {
            TuckIcons.shared.toggle()
        }

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
        // Accessory apps must switch to regular policy to bring a window to the front
        NSApp.setActivationPolicy(.regular)
        settingsWindowController.show(pane: .general)
        settingsWindowController.window?.makeKeyAndOrderFront(nil)
        settingsWindowController.window?.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        // Return to accessory (no Dock icon) when the settings window closes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsWindowClosed),
            name: NSWindow.willCloseNotification,
            object: settingsWindowController.window
        )
    }

    @objc private func settingsWindowClosed() {
        NotificationCenter.default.removeObserver(
            self,
            name: NSWindow.willCloseNotification,
            object: settingsWindowController.window
        )
        NSApp.setActivationPolicy(.accessory)
    }

    lazy var settingsWindowController = SettingsWindowController(
        panes: [General()],
        style: .toolbarItems,
        animated: true,
        hidesToolbarForSingleItem: true
    )
}
