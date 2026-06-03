/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import Defaults

public final class DozerIcons {
    static var shared = DozerIcons()
    private var dozerIcons: [HelperstatusIcon] = []
    private var timerToHideDozerIcons = Timer()

    private init() {
        dozerIcons.append(NormalStatusIcon())

        if !hideBothDozerIcons || !Defaults[.isShortcutSet] {
            dozerIcons.append(NormalStatusIcon())
        }

        if enableRemoveDozerIcon {
            dozerIcons.append(RemoveStatusIcon())
        }

        if hideStatusBarIconsAfterDelay {
            startTimer()
        }

        Defaults.observe(.isShortcutSet) { _ in
            self.triggerHideBothDozerIcons()
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

    public var hideBothDozerIcons: Bool = Defaults[.noIconMode] {
        didSet {
            Defaults[.noIconMode] = self.hideBothDozerIcons
            triggerHideBothDozerIcons()
        }
    }

    public func triggerHideBothDozerIcons() {
        let normalStatusIconsCount = dozerIcons.filter { $0.type == .normal }.count
        if hideBothDozerIcons && Defaults[.isShortcutSet] {
            if normalStatusIconsCount == 2 {
                let rightDozerIconXPos = get(dozerIcon: .normalRight).xPositionOnScreen
                dozerIcons.removeAll { $0.xPositionOnScreen == rightDozerIconXPos }
            }
        } else if !hideBothDozerIcons && Defaults[.isShortcutSet] || !Defaults[.isShortcutSet] {
            if normalStatusIconsCount == 1 {
                show()
                dozerIcons.append(NormalStatusIcon())
            }
        }
        show()
    }

    public var enableRemoveDozerIcon: Bool = Defaults[.removeDozerIconEnabled] {
        didSet {
            Defaults[.removeDozerIconEnabled] = self.enableRemoveDozerIcon
            if enableRemoveDozerIcon {
                dozerIcons.append(RemoveStatusIcon())
            } else {
                dozerIcons.removeAll { $0.type == .remove }
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
        if get(dozerIcon: .normalLeft).isShown {
            hide()
        } else {
            show()
        }
    }

    public func toggleRemove() {
        if get(dozerIcon: .remove).isShown {
            perform(action: .hide, statusIcon: .remove)
        } else {
            perform(action: .show, statusIcon: .remove)
        }
    }

    /// Force show all Dozer icons
    public func showAll() {
        perform(action: .show, statusIcon: .remove)
        perform(action: .show, statusIcon: .normalLeft)
        perform(action: .show, statusIcon: .normalRight)
    }

    public func handleOptionClick() {
        if get(dozerIcon: .normalLeft).isShown {
            DozerIcons.shared.perform(action: .toggle, statusIcon: .remove)
        } else {
            DozerIcons.shared.perform(action: .show, statusIcon: .normalLeft)
            DozerIcons.shared.perform(action: .show, statusIcon: .remove)
        }
        resetTimer()
    }

    // MARK: Timer methods

    private func startTimer() {
        guard Defaults[.hideAfterDelayEnabled] else {
            stopTimer()
            return
        }
        timerToHideDozerIcons = Timer.scheduledTimer(withTimeInterval: Defaults[.hideAfterDelay], repeats: false) { _ in
            self.hide()
        }
    }

    private func stopTimer() {
        timerToHideDozerIcons.invalidate()
    }

    func resetTimer() {
        stopTimer()
        startTimer()
    }

    // MARK: Private methods

    /// Will fail silently if statusIcon does not exist
    private func perform(action: StatusIconAction, statusIcon: DozerIcon) {
        if statusIcon == .remove {
            guard Defaults[.removeDozerIconEnabled] else { return }
        }
        let theStatusIcon: HelperstatusIcon = get(dozerIcon: statusIcon)
        switch action {
        case .show: theStatusIcon.show()
        case .hide: theStatusIcon.hide()
        case .toggle: theStatusIcon.toggle()
        }
    }

    /// Will crash if trying to get a DozerIcon which does not exist in the menu bar
    private func get(dozerIcon: DozerIcon) -> HelperstatusIcon {
        var normalStatusIconsXPosition: [CGFloat] = []
        for statusIcon in dozerIcons where statusIcon.type == .normal {
            normalStatusIconsXPosition.append(statusIcon.xPositionOnScreen)
        }
        switch dozerIcon {
        case .remove:
            guard let removeStatusIcon = dozerIcons.first(where: { $0.type == .remove }) else {
                fatalError("Failed getting remove status icon")
            }
            return removeStatusIcon
        case .normalLeft:
            guard let leftStatusIcon = dozerIcons.first(where: { $0.xPositionOnScreen == normalStatusIconsXPosition.min() }) else {
                fatalError("Failed getting status icon on the left")
            }
            return leftStatusIcon
        case .normalRight:
            guard let rightStatusIcon = dozerIcons.first(where: { $0.xPositionOnScreen == normalStatusIconsXPosition.max() }) else {
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
