//
//  SettingsViewController.swift
//  Tasks
//
//  Created by Daniel Adams on 09.03.19.
//  Copyright © 2019 Entire. All rights reserved.
//

import UIKit
import SDWebImage

protocol ReusableViewEnum {}

extension ReusableViewEnum where Self: RawRepresentable, Self.RawValue == Int {
    static var all: [Self] {
        var index = 0
        var allItems = [Self]()
        while let item = Self(rawValue: index) {
            allItems.append(item)
            index += 1
        }
        return allItems
    }

    static func build(with value: Int) -> Self {
        guard let row = Self(rawValue: value) else {
            fatalError("Unimplemented value: \(value)")
        }
        return row
    }
}

private enum SettingsSections: Int, ReusableViewEnum {
    case account = 0
    case appearance
    case debug
}

class SettingsViewController: EntireTableViewController {
    var accountHelper = SettingsAccountHelper()
    var appearanceHelper = SettingsAppearanceHelper()
    var debugHelper = SettingsDebugHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return SettingsSections.all.count - debugOffset()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch SettingsSections.build(with: section) {
        case .account:
            return 2
        case .appearance:
            return 3
        case .debug:
            return 3
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch SettingsSections.build(with: indexPath.section) {
        case .account:
            return accountHelper.tableView(tableView, cellForRow: indexPath.row)
        case .appearance:
            appearanceHelper.overrideUserInterfaceStyle = self.overrideUserInterfaceStyle
            return appearanceHelper.tableView(tableView, cellForRow: indexPath.row)
        case .debug:
            return debugHelper.tableView(tableView, cellForRow: indexPath.row)
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch SettingsSections.build(with: indexPath.section) {
        case .account:
            accountHelper.tableView(tableView, didSelectRow: indexPath.row, viewController: self)
        case .appearance:
            appearanceHelper.tableView(tableView, didSelectRow: indexPath.row, viewController: self)
        case .debug:
            debugHelper.tableView(tableView, didSelectRow: indexPath.row, viewController: self)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch SettingsSections.build(with: section) {
        case .account:
            return "Account"
        case .appearance:
            return "Appearance"
        case .debug:
            return "Debug"
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        self.navigationController!.dismiss(animated: true)
    }

    func debugOffset() -> Int {
        return Constants.debug ? 0 : 1
    }
}
