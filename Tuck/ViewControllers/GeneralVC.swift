/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import Settings
import Defaults
import LaunchAtLogin
import KeyboardShortcuts

final class General: NSViewController, SettingsPane {
    let paneIdentifier = Settings.PaneIdentifier.general
    let paneTitle = "General"
    let toolbarItemIcon = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")!

    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
    private let hideAtLaunchCheckbox = NSButton(checkboxWithTitle: "Hide at launch", target: nil, action: nil)
    private let hideAfterDelayCheckbox = NSButton(checkboxWithTitle: "Hide after delay", target: nil, action: nil)
    private let hideAfterDelayPopup = NSPopUpButton()
    private let enableRemoveIconCheckbox = NSButton(checkboxWithTitle: "Enable remove icon", target: nil, action: nil)
    private let hideBothIconsCheckbox = NSButton(checkboxWithTitle: "Hide both Tuck icons (requires shortcut)", target: nil, action: nil)
    private let shortcutRecorder = KeyboardShortcuts.RecorderCocoa(for: .toggleMenuItems)

    private let delayValues: [TimeInterval] = [5, 10, 30, 60]

    override func loadView() {
        let delayRow = NSStackView(views: [hideAfterDelayCheckbox, hideAfterDelayPopup])
        delayRow.spacing = 8
        delayRow.alignment = .centerY

        let shortcutLabel = NSTextField(labelWithString: "Toggle shortcut:")
        shortcutLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        let shortcutRow = NSStackView(views: [shortcutLabel, shortcutRecorder])
        shortcutRow.spacing = 8
        shortcutRow.alignment = .centerY

        let quitButton = NSButton(title: "Quit Tuck", target: NSApp, action: #selector(NSApp.terminate(_:)))

        let stack = NSStackView(views: [
            launchAtLoginCheckbox,
            hideAtLaunchCheckbox,
            delayRow,
            enableRemoveIconCheckbox,
            hideBothIconsCheckbox,
            shortcutRow,
            quitButton
        ])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        let container = NSView()
        container.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: container.topAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 320)
        ])

        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Populate delay popup
        for value in delayValues {
            let title = value == 1 ? "1 second" : "\(Int(value)) seconds"
            hideAfterDelayPopup.addItem(withTitle: title)
            hideAfterDelayPopup.lastItem?.tag = Int(value)
        }

        // Set initial states
        launchAtLoginCheckbox.isChecked = LaunchAtLogin.isEnabled
        hideAtLaunchCheckbox.isChecked = Defaults[.hideAtLaunchEnabled]
        hideAfterDelayCheckbox.isChecked = Defaults[.hideAfterDelayEnabled]
        enableRemoveIconCheckbox.isChecked = Defaults[.removeTuckIconEnabled]
        hideBothIconsCheckbox.isChecked = Defaults[.noIconMode]
        hideAfterDelayPopup.selectItem(withTag: Int(Defaults[.hideAfterDelay]))

        // Wire targets/actions
        launchAtLoginCheckbox.target = self
        launchAtLoginCheckbox.action = #selector(launchAtLoginChanged)

        hideAtLaunchCheckbox.target = self
        hideAtLaunchCheckbox.action = #selector(hideAtLaunchChanged)

        hideAfterDelayCheckbox.target = self
        hideAfterDelayCheckbox.action = #selector(hideAfterDelayChanged)

        hideAfterDelayPopup.target = self
        hideAfterDelayPopup.action = #selector(hideAfterDelaySecondsChanged)

        enableRemoveIconCheckbox.target = self
        enableRemoveIconCheckbox.action = #selector(enableRemoveIconChanged)

        hideBothIconsCheckbox.target = self
        hideBothIconsCheckbox.action = #selector(hideBothIconsChanged)

        updateHideBothIconsState()

        // Update hide-both-icons checkbox when shortcut changes
        KeyboardShortcuts.onKeyUp(for: .toggleMenuItems) { [weak self] in
            self?.updateHideBothIconsState()
        }
    }

    // MARK: - Actions

    @objc private func launchAtLoginChanged() {
        LaunchAtLogin.isEnabled = launchAtLoginCheckbox.isChecked
    }

    @objc private func hideAtLaunchChanged() {
        TuckIcons.shared.hideStatusBarIconsAtLaunch = hideAtLaunchCheckbox.isChecked
    }

    @objc private func hideAfterDelayChanged() {
        TuckIcons.shared.hideStatusBarIconsAfterDelay = hideAfterDelayCheckbox.isChecked
    }

    @objc private func hideAfterDelaySecondsChanged() {
        Defaults[.hideAfterDelay] = TimeInterval(hideAfterDelayPopup.selectedTag())
        TuckIcons.shared.resetTimer()
    }

    @objc private func enableRemoveIconChanged() {
        TuckIcons.shared.enableRemoveTuckIcon = enableRemoveIconCheckbox.isChecked
    }

    @objc private func hideBothIconsChanged() {
        TuckIcons.shared.hideBothTuckIcons = hideBothIconsCheckbox.isChecked
    }

    // MARK: - Helpers

    private func updateHideBothIconsState() {
        let shortcutIsSet = KeyboardShortcuts.getShortcut(for: .toggleMenuItems) != nil
        Defaults[.isShortcutSet] = shortcutIsSet
        hideBothIconsCheckbox.isEnabled = shortcutIsSet
        if !shortcutIsSet {
            hideBothIconsCheckbox.isChecked = false
            Defaults[.noIconMode] = false
        }
    }
}
