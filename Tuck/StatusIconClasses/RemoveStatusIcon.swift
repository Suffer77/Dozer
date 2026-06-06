/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa

class RemoveStatusIcon: HelperstatusIcon {
    override init() {
        super.init()
        type = .remove
    }

    override func statusIconClicked(_: AnyObject?) {
        guard let currentEvent = NSApp.currentEvent else { return }

        switch currentEvent.type {
        case .leftMouseDown:
            TuckIcons.shared.toggleRemove()
        case .rightMouseDown:
            appDelegate.showSettings()
        default:
            break
        }
    }

    override func setIcon() {
        guard let statusIconButton = statusIcon.button else {
            fatalError("helper status item button failed")
        }
        let config = NSImage.SymbolConfiguration(pointSize: 8, weight: .medium)
        statusIconButton.image = NSImage(systemSymbolName: "chevron.compact.left", accessibilityDescription: nil)?
            .withSymbolConfiguration(config)
        statusIconButton.image?.isTemplate = true
    }
}
