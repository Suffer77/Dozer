/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at https://mozilla.org/MPL/2.0/. */

import Cocoa
import ServiceManagement

final class General: NSViewController {
    private let launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at login", target: nil, action: nil)
    private let hideAtLaunchCheckbox = NSButton(checkboxWithTitle: "Hide at launch", target: nil, action: nil)
    private let hideAfterDelayCheckbox = NSButton(checkboxWithTitle: "Hide after delay", target: nil, action: nil)
    private let hideAfterDelayPopup: NSPopUpButton = {
        let popup = NSPopUpButton()
        popup.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return popup
    }()
    private let enableRemoveIconCheckbox = NSButton(checkboxWithTitle: "Enable remove icon", target: nil, action: nil)
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
        grid.addRow(with: [quitButton, NSGridCell.emptyContentView])

        grid.column(at: 0).xPlacement = .leading
        grid.column(at: 1).xPlacement = .leading
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
            grid.bottomAnchor.constraint(lessThanOrEqualTo: container.bottomAnchor, constant: -20),
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

        launchAtLoginCheckbox.isChecked = SMAppService.mainApp.status == .enabled
        hideAtLaunchCheckbox.isChecked = AppSettings.hideAtLaunchEnabled
        hideAfterDelayCheckbox.isChecked = AppSettings.hideAfterDelayEnabled
        enableRemoveIconCheckbox.isChecked = AppSettings.removeTuckIconEnabled
        hideAfterDelayPopup.selectItem(withTag: Int(AppSettings.hideAfterDelay))

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
    }

    // MARK: - Actions

    @objc private func launchAtLoginChanged() {
        do {
            if launchAtLoginCheckbox.isChecked {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            launchAtLoginCheckbox.isChecked = SMAppService.mainApp.status == .enabled
            presentLaunchAtLoginError(error)
        }
    }

    @objc private func hideAtLaunchChanged() {
        TuckIcons.shared.hideStatusBarIconsAtLaunch = hideAtLaunchCheckbox.isChecked
    }

    @objc private func hideAfterDelayChanged() {
        TuckIcons.shared.hideStatusBarIconsAfterDelay = hideAfterDelayCheckbox.isChecked
    }

    @objc private func hideAfterDelaySecondsChanged() {
        AppSettings.hideAfterDelay = TimeInterval(hideAfterDelayPopup.selectedTag())
        TuckIcons.shared.resetTimer()
    }

    @objc private func enableRemoveIconChanged() {
        TuckIcons.shared.enableRemoveTuckIcon = enableRemoveIconCheckbox.isChecked
    }

    private func presentLaunchAtLoginError(_ error: Error) {
        let alert = NSAlert(error: error)
        alert.messageText = "Could not update Launch at Login"
        alert.informativeText = "You can also manage this in System Settings → General → Login Items."
        alert.runModal()
    }
}
