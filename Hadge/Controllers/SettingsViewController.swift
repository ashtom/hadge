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
    case sync
    case about
    case debug
}

class SettingsViewController: EntireTableViewController {
    var accountHelper = SettingsAccountHelper()
    var appearanceHelper = SettingsAppearanceHelper()
    var debugHelper = SettingsDebugHelper()
    var aboutHelper = SettingsAboutHelper()
    var syncHelper = SettingsSyncHelper()

    deinit {
        NotificationCenter.default.removeObserver(self)
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
        case .sync:
            return 1
        case .about:
            return 1
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
        case .sync:
            return syncHelper.tableView(tableView, cellForRow: indexPath.row)
        case .about:
            return aboutHelper.tableView(tableView, cellForRow: indexPath.row)
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
        case .sync:
            syncHelper.tableView(tableView, didSelectRow: indexPath.row, viewController: self)
        case .about:
            aboutHelper.tableView(tableView, didSelectRow: indexPath.row, viewController: self)
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
        case .sync:
            return "Sync"
        case .about:
            return "About"
        case .debug:
            return "Debug"
        }
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch SettingsSections.build(with: section) {
        case .account:
            return nil
        case .appearance:
            return nil
        case .sync:
            return "This will re-upload all activity, distance, and workout data for all years with available data. You typically don't need to do this unless you deleted the repository or files in it."
        case .about:
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
            return "You are using Hadge \(version!) (\(build!)).\nMade with ❤️ in Seattle."
        case .debug:
            return "This section will be removed in the release build."
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "UploadSegue" {
            let setupViewController = segue.destination as? SetupViewController
            setupViewController?.delegate = self
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        self.navigationController!.dismiss(animated: true)
    }

    @objc func didFinishUpload() {
        NotificationCenter.default.removeObserver(self, name: .didSetUpRepository, object: nil)
    }

    func debugOffset() -> Int {
        return Constants.debug ? 0 : 1
    }
}
