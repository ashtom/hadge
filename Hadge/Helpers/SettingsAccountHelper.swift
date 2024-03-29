import UIKit

class SettingsAccountHelper {
    func tableView(_ tableView: UITableView, cellForRow: Int) -> UITableViewCell {
        switch cellForRow {
        case 0:
            let identifier = "AccountCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? AccountCell
            let username = GitHub.shared().returnAuthenticatedUsername()
            let avatarURL = "https://github.com/\(username).png?size=102"
            cell?.avatarView.sd_setImage(with: URL(string: avatarURL), completed: nil)

            let fullname = GitHub.shared().fullname()
            if fullname == nil || fullname!.isEmpty {
                cell?.nameLabel.text = "@\(GitHub.shared().username() ?? "")"
                cell?.loginLabel.text = ""
            } else {
                cell?.nameLabel.text = GitHub.shared().fullname() ?? ""
                cell?.loginLabel.text = "@\(GitHub.shared().username() ?? "")"
            }
            return cell!
        default:
            let identifier = "SettingsCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)
            cell.separatorInset = UIEdgeInsets.init(top: 0, left: 15.0, bottom: 0, right: 0)
            cell.textLabel?.text = "Sign out"
            cell.textLabel?.textColor = UIColor.systemRed
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRow: Int, viewController: SettingsViewController) {
        switch didSelectRow {
        case 1:
            GitHub.shared().signOut()
            Health.shared().healthStore?.disableAllBackgroundDelivery { _, _ in }
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.setupFinished)
            UserDefaults.standard.synchronize()
            viewController.dismiss(animated: false) {
                NotificationCenter.default.post(name: .didSignOut, object: nil)
            }
        default:
            break
        }
    }
}
