import UIKit

class SettingsAppearanceHelper {
    var overrideUserInterfaceStyle: UIUserInterfaceStyle = .unspecified

    func tableView(_ tableView: UITableView, cellForRow: Int) -> UITableViewCell {
        let identifier = "AppearanceCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)
        cell.separatorInset = UIEdgeInsets.init(top: 0, left: 15.0, bottom: 0, right: 0)
        cell.selectionStyle = .none

        switch cellForRow {
        case 0:
            cell.textLabel?.text = "Automatic"
            cell.accessoryType = (self.overrideUserInterfaceStyle == .unspecified ? .checkmark : .none)
        case 1:
            cell.textLabel?.text = "Dark"
            cell.accessoryType = (self.overrideUserInterfaceStyle == .dark ? .checkmark : .none)
        case 2:
            cell.textLabel?.text = "Light"
            cell.accessoryType = (self.overrideUserInterfaceStyle == .light ? .checkmark : .none)
        default:
            cell.textLabel?.text = "Undefined"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRow: Int, viewController: SettingsViewController) {
        var newInterfaceStyle: InterfaceStyle
        switch didSelectRow {
        case 1:
            newInterfaceStyle = .dark
        case 2:
            newInterfaceStyle = .light
        default:
            newInterfaceStyle = .automatic
        }

        UserDefaults.standard.setValue(newInterfaceStyle.rawValue, forKeyPath: UserDefaultKeys.interfaceStyle)

        tableView.reloadData()
        viewController.setInterfaceStyle()
        viewController.navigationController?.setInterfaceStyle()

        NotificationCenter.default.post(name: .didChangeInterfaceStyle, object: nil)
    }
}
