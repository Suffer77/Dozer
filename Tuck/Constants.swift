/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import Settings
import Defaults
import KeyboardShortcuts

extension Defaults.Keys {
    static let hideAtLaunchEnabled: Defaults.Key<Bool> = Key<Bool>("hideAtLaunchEnabled", default: false)
    static let hideAfterDelayEnabled: Defaults.Key<Bool> = Key<Bool>("hideAfterDelayEnabled", default: false)
    static let hideAfterDelay: Defaults.Key<TimeInterval> = Key<TimeInterval>("hideAfterDelay", default: 10)
    static let noIconMode: Defaults.Key<Bool> = Key<Bool>("noIconMode", default: false)
    static let removeTuckIconEnabled: Defaults.Key<Bool> = Key<Bool>("removeTuckIconEnabled", default: false)
    static let isShortcutSet: Defaults.Key<Bool> = Key<Bool>("isShortcutSet", default: false)
}

extension KeyboardShortcuts.Name {
    static let toggleMenuItems = Self("toggleMenuItems")
}

extension Settings.PaneIdentifier {
    static let general = Self("general")
}

struct AppInfo {
    static let bundleIdentifier: String = Bundle.main.bundleIdentifier!
}

enum StatusIconAction {
    case show
    case hide
    case toggle
}

enum StatusIconType {
    case normal
    case remove
}

enum TuckIcon {
    case remove
    case normalLeft
    case normalRight
}
