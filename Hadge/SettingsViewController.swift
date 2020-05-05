//
//  SettingsViewController.swift
//  Tasks
//
//  Created by Daniel Adams on 09.03.19.
//  Copyright © 2019 Entire. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    var workoutSemaphore = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SettingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Clear last workout UUID"
            case 1:
                cell.textLabel?.text = "Force upload workouts"
            default:
                cell.textLabel?.text = "Undefined"
            }
        case 1:
            cell.textLabel?.text = "Sign Out"
        default:
            cell.textLabel?.text = "Undefined"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)

            switch indexPath.row {
            case 0:
                UserDefaults.standard.set(nil, forKey: UserDefaultKeys.lastWorkout)
            case 1:
                if workoutSemaphore { return }

                workoutSemaphore = true
                Health.shared().loadWorkouts { workouts in
                    guard let workouts = workouts, workouts.count > 0 else { return }

                    let content = Health.shared().generateContentForWorkouts(workouts: workouts)
                    let filename = "workouts/\(Health.shared().year).csv"
                    GitHub.shared().updateFile(path: filename, content: content, message: "Update workouts from Hadge.app") { _ in
                        self.workoutSemaphore = false
                    }
                }
            default: // No op
                break
            }
        case 1:
            _ = GitHub.shared().signOut()

            let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
            sceneDelegate?.window?.rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginViewController")
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Debug"
        case 1:
            return "Account"
        default:
            return ""
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        self.navigationController!.dismiss(animated: true)
    }
}
