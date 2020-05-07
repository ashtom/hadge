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
        return 2 - debugOffset()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section + debugOffset() {
        case 0:
            return 4
        case 1:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "SettingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)

        switch indexPath.section + debugOffset() {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Seed sample data (Simulator only)"
            case 1:
                cell.textLabel?.text = "Clear last workout UUID"
            case 2:
                cell.textLabel?.text = "Force upload workouts"
            case 3:
                cell.textLabel?.text = "Show setup flow on next launch"
            default:
                cell.textLabel?.text = "Undefined"
            }
        case 1:
            cell.textLabel?.text = "Sign out"
        default:
            cell.textLabel?.text = "Undefined"
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section + debugOffset() {
        case 0:
            tableView.deselectRow(at: indexPath, animated: true)

            switch indexPath.row {
            case 0:
                #if targetEnvironment(simulator)
                Health.shared().seedSampleData()
                #else
                break
                #endif
            case 1:
                UserDefaults.standard.set(nil, forKey: UserDefaultKeys.lastWorkout)
            case 2:
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
            case 3:
                UserDefaults.standard.set(false, forKey: UserDefaultKeys.setupFinished)
            default: // No op
                break
            }
        case 1:
            _ = GitHub.shared().signOut()
            self.dismiss(animated: false) {
                NotificationCenter.default.post(name: .didSignOut, object: nil)
            }
        default:
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section + debugOffset() {
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

    func debugOffset() -> Int {
        return Constants.debug ? 0 : 1
    }
}
