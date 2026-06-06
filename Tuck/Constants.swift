/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa

enum AppSettings {
    private enum Key {
        static let hideAtLaunchEnabled = "hideAtLaunchEnabled"
        static let hideAfterDelayEnabled = "hideAfterDelayEnabled"
        static let hideAfterDelay = "hideAfterDelay"
        static let removeTuckIconEnabled = "removeTuckIconEnabled"
    }

    static var hideAtLaunchEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.hideAtLaunchEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Key.hideAtLaunchEnabled) }
    }

    static var hideAfterDelayEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.hideAfterDelayEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Key.hideAfterDelayEnabled) }
    }

    static var hideAfterDelay: TimeInterval {
        get {
            let value = UserDefaults.standard.double(forKey: Key.hideAfterDelay)
            return value > 0 ? value : 10
        }
        set { UserDefaults.standard.set(newValue, forKey: Key.hideAfterDelay) }
    }

    static var removeTuckIconEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Key.removeTuckIconEnabled) }
        set { UserDefaults.standard.set(newValue, forKey: Key.removeTuckIconEnabled) }
    }
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
