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

    lazy var settingsWindowController = SettingsWindowController(
        panes: [General()],
        style: .toolbarItems,
        animated: true,
        hidesToolbarForSingleItem: true
    )
}
