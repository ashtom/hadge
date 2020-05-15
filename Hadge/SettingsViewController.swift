//
//  SettingsViewController.swift
//  Tasks
//
//  Created by Daniel Adams on 09.03.19.
//  Copyright © 2019 Entire. All rights reserved.
//

import UIKit
import SDWebImage

class SettingsViewController: EntireTableViewController {
    var workoutSemaphore = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 - debugOffset()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 3
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SettingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)
        cell.separatorInset = UIEdgeInsets.init(top: 0, left: 15.0, bottom: 0, right: 0)

        switch indexPath.section {
        case 0:
            return accountCellForRow(indexPath.row)
        case 1:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Force upload on next refresh"
            case 1:
                cell.textLabel?.text = "Force upload workouts now"
            case 2:
                cell.textLabel?.text = "Show setup flow on next launch"
            default:
                cell.textLabel?.text = "Undefined"
            }
        default:
            cell.textLabel?.text = "Undefined"
        }
        return cell
    }

    func accountCellForRow(_ row: Int) -> UITableViewCell {
        switch row {
        case 0:
            let identifier = "AccountCell"
            let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? AccountCell
            let username = GitHub.shared().returnAuthenticatedUsername()
            let avatarURL = "https://github.com/\(username).png?size=102"
            cell?.avatarView.sd_setImage(with: URL(string: avatarURL), completed: nil)
            cell?.nameLabel.text = GitHub.shared().fullname() ?? ""
            cell?.loginLabel.text = "@\(GitHub.shared().username() ?? "")"
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)

            switch indexPath.row {
            case 1:
                _ = GitHub.shared().signOut()
                self.dismiss(animated: false) {
                    NotificationCenter.default.post(name: .didSignOut, object: nil)
                }
            default:
                break
            }
        case 1:
            tableView.deselectRow(at: indexPath, animated: true)
            handleDebugOptionsInRow(indexPath.row)
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    func handleDebugOptionsInRow(_ row: Int) {
        switch row {
        case 0:
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.lastWorkout)
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.lastSyncDate)
            UserDefaults.standard.set(nil, forKey: UserDefaultKeys.lastActivitySyncDate)
            UserDefaults.standard.synchronize()
        case 1:
            if workoutSemaphore { return }

            workoutSemaphore = true
            Health.shared().getWorkouts { workouts in
                guard let workouts = workouts, workouts.count > 0 else { return }

                let content = Health.shared().generateContentForWorkouts(workouts: workouts)
                let filename = "workouts/\(Health.shared().year).csv"
                GitHub.shared().updateFile(path: filename, content: content, message: "Update workouts") { _ in
                    self.workoutSemaphore = false
                }
            }
        case 2:
            UserDefaults.standard.set(false, forKey: UserDefaultKeys.setupFinished)
            UserDefaults.standard.synchronize()
        default: // No op
            break
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section + debugOffset() {
        case 0:
            return "Account"
        case 1:
            return "Debug"
        default:
            return ""
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        self.navigationController!.dismiss(animated: true)
    }

    func debugOffset() -> Int {
        return Constants.debug ? 0 : 1
    }
}
