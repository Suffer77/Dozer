/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import Defaults

public final class TuckIcons {
    static var shared = TuckIcons()
    private var tuckIcons: [HelperstatusIcon] = []
    private var timerToHideTuckIcons = Timer()

    private init() {
        tuckIcons.append(NormalStatusIcon())

        if !hideBothTuckIcons || !Defaults[.isShortcutSet] {
            tuckIcons.append(NormalStatusIcon())
        }

        if enableRemoveTuckIcon {
            tuckIcons.append(RemoveStatusIcon())
        }

        if hideStatusBarIconsAfterDelay {
            startTimer()
        }

        Defaults.observe(.isShortcutSet) { _ in
            self.triggerHideBothTuckIcons()
        }
        .tieToLifetime(of: self)
    }

    // MARK: Observe changes to settings

    public var hideStatusBarIconsAtLaunch: Bool = Defaults[.hideAtLaunchEnabled] {
        didSet {
            Defaults[.hideAtLaunchEnabled] = self.hideStatusBarIconsAtLaunch
        }
    }

    public var hideStatusBarIconsAfterDelay: Bool = Defaults[.hideAfterDelayEnabled] {
        didSet {
            Defaults[.hideAfterDelayEnabled] = self.hideStatusBarIconsAfterDelay
            if hideStatusBarIconsAfterDelay {
                startTimer()
            } else {
                stopTimer()
            }
        }
    }

    public var hideBothTuckIcons: Bool = Defaults[.noIconMode] {
        didSet {
            Defaults[.noIconMode] = self.hideBothTuckIcons
            triggerHideBothTuckIcons()
        }
    }

    public func triggerHideBothTuckIcons() {
        let normalStatusIconsCount = tuckIcons.filter { $0.type == .normal }.count
        if hideBothTuckIcons && Defaults[.isShortcutSet] {
            if normalStatusIconsCount == 2 {
                let rightTuckIconXPos = get(tuckIcon: .normalRight).xPositionOnScreen
                tuckIcons.removeAll { $0.xPositionOnScreen == rightTuckIconXPos }
            }
        } else if !hideBothTuckIcons && Defaults[.isShortcutSet] || !Defaults[.isShortcutSet] {
            if normalStatusIconsCount == 1 {
                show()
                tuckIcons.append(NormalStatusIcon())
            }
        }
        show()
    }

    public var enableRemoveTuckIcon: Bool = Defaults[.removeTuckIconEnabled] {
        didSet {
            Defaults[.removeTuckIconEnabled] = self.enableRemoveTuckIcon
            if enableRemoveTuckIcon {
                tuckIcons.append(RemoveStatusIcon())
            } else {
                tuckIcons.removeAll { $0.type == .remove }
            }
            showAll()
        }
    }

    // MARK: Public methods

    public func hide() {
        perform(action: .hide, statusIcon: .remove)
        perform(action: .hide, statusIcon: .normalLeft)
        if Defaults[.noIconMode] && Defaults[.isShortcutSet] {
            perform(action: .hide, statusIcon: .normalRight)
        }
        stopTimer()
    }

    public func hideAtLaunch() {
        guard hideStatusBarIconsAtLaunch else { return }
        Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { _ in
            self.hide()
        }
    }

    public func show() {
        resetTimer()
        perform(action: .hide, statusIcon: .remove)
        perform(action: .show, statusIcon: .normalLeft)
        if Defaults[.noIconMode] {
            perform(action: .show, statusIcon: .normalRight)
        }
    }

    public func toggle() {
        if get(tuckIcon: .normalLeft).isShown {
            hide()
        } else {
            show()
        }
    }

    public func toggleRemove() {
        if get(tuckIcon: .remove).isShown {
            perform(action: .hide, statusIcon: .remove)
        } else {
            perform(action: .show, statusIcon: .remove)
        }
    }

    /// Force show all Tuck icons
    public func showAll() {
        perform(action: .show, statusIcon: .remove)
        perform(action: .show, statusIcon: .normalLeft)
        perform(action: .show, statusIcon: .normalRight)
    }

    public func handleOptionClick() {
        if get(tuckIcon: .normalLeft).isShown {
            TuckIcons.shared.perform(action: .toggle, statusIcon: .remove)
        } else {
            TuckIcons.shared.perform(action: .show, statusIcon: .normalLeft)
            TuckIcons.shared.perform(action: .show, statusIcon: .remove)
        }
        resetTimer()
    }

    // MARK: Timer methods

    private func startTimer() {
        guard Defaults[.hideAfterDelayEnabled] else {
            stopTimer()
            return
        }
        timerToHideTuckIcons = Timer.scheduledTimer(withTimeInterval: Defaults[.hideAfterDelay], repeats: false) { _ in
            self.hide()
        }
    }

    private func stopTimer() {
        timerToHideTuckIcons.invalidate()
    }

    func resetTimer() {
        stopTimer()
        startTimer()
    }

    // MARK: Private methods

    private func perform(action: StatusIconAction, statusIcon: TuckIcon) {
        if statusIcon == .remove {
            guard Defaults[.removeTuckIconEnabled] else { return }
        }
        let theStatusIcon: HelperstatusIcon = get(tuckIcon: statusIcon)
        switch action {
        case .show: theStatusIcon.show()
        case .hide: theStatusIcon.hide()
        case .toggle: theStatusIcon.toggle()
        }
    }

    /// Will crash if trying to get a TuckIcon which does not exist in the menu bar
    private func get(tuckIcon: TuckIcon) -> HelperstatusIcon {
        var normalStatusIconsXPosition: [CGFloat] = []
        for statusIcon in tuckIcons where statusIcon.type == .normal {
            normalStatusIconsXPosition.append(statusIcon.xPositionOnScreen)
        }
        switch tuckIcon {
        case .remove:
            guard let removeStatusIcon = tuckIcons.first(where: { $0.type == .remove }) else {
                fatalError("Failed getting remove status icon")
            }
            return removeStatusIcon
        case .normalLeft:
            guard let leftStatusIcon = tuckIcons.first(where: { $0.xPositionOnScreen == normalStatusIconsXPosition.min() }) else {
                fatalError("Failed getting status icon on the left")
            }
            return leftStatusIcon
        case .normalRight:
            guard let rightStatusIcon = tuckIcons.first(where: { $0.xPositionOnScreen == normalStatusIconsXPosition.max() }) else {
                fatalError("Failed getting status icon on the right")
            }
            return rightStatusIcon
        }
    }

    /// Toggle between accessory (no Dock icon) and regular (Dock icon visible)
    public class func toggleDockIcon(showIcon state: Bool) -> Bool {
        if state {
            return NSApp.setActivationPolicy(.regular)
        } else {
            return NSApp.setActivationPolicy(.accessory)
        }
    }
}
