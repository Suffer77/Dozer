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
    private let hideAfterDelayPopup: NSPopUpButton = {
        let popup = NSPopUpButton()
        popup.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return popup
    }()
    private let enableRemoveIconCheckbox = NSButton(checkboxWithTitle: "Enable remove icon", target: nil, action: nil)
    private let hideBothIconsCheckbox = NSButton(checkboxWithTitle: "Hide both Tuck icons (requires shortcut)", target: nil, action: nil)
    private let shortcutLabel = NSTextField(labelWithString: "Toggle shortcut:")
    private let shortcutRecorder = KeyboardShortcuts.RecorderCocoa(for: .toggleMenuItems)
    private let quitButton = NSButton(title: "Quit Tuck", target: NSApp, action: #selector(NSApp.terminate(_:)))

    private let delayValues: [TimeInterval] = [5, 10, 30, 60]

    override func loadView() {
        let grid = NSGridView()
        grid.columnSpacing = 8
        grid.rowSpacing = 10
        grid.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        grid.addRow(with: [launchAtLoginCheckbox, NSGridCell.emptyContentView])
        grid.addRow(with: [hideAtLaunchCheckbox, NSGridCell.emptyContentView])
        grid.addRow(with: [hideAfterDelayCheckbox, hideAfterDelayPopup])
        grid.addRow(with: [enableRemoveIconCheckbox, NSGridCell.emptyContentView])
        grid.addRow(with: [hideBothIconsCheckbox, NSGridCell.emptyContentView])
        grid.addRow(with: [shortcutLabel, shortcutRecorder])
        grid.addRow(with: [quitButton, NSGridCell.emptyContentView])

        // Left-align the label column
        grid.column(at: 0).xPlacement = .leading
        grid.column(at: 1).xPlacement = .leading
        // Vertically center all rows
        for i in 0..<grid.numberOfRows {
            grid.row(at: i).yPlacement = .center
        }

        let container = NSView()
        container.addSubview(grid)
        grid.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            grid.topAnchor.constraint(equalTo: container.topAnchor, constant: 20),
            grid.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            grid.trailingAnchor.constraint(lessThanOrEqualTo: container.trailingAnchor, constant: -20),
            grid.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -20),
            container.widthAnchor.constraint(greaterThanOrEqualToConstant: 340)
        ])

        view = container
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        for value in delayValues {
            let title = "\(Int(value)) seconds"
            hideAfterDelayPopup.addItem(withTitle: title)
            hideAfterDelayPopup.lastItem?.tag = Int(value)
        }

        launchAtLoginCheckbox.isChecked = LaunchAtLogin.isEnabled
        hideAtLaunchCheckbox.isChecked = Defaults[.hideAtLaunchEnabled]
        hideAfterDelayCheckbox.isChecked = Defaults[.hideAfterDelayEnabled]
        enableRemoveIconCheckbox.isChecked = Defaults[.removeTuckIconEnabled]
        hideBothIconsCheckbox.isChecked = Defaults[.noIconMode]
        hideAfterDelayPopup.selectItem(withTag: Int(Defaults[.hideAfterDelay]))

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
