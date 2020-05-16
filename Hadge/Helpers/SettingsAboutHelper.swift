//
//  SettingsAboutHelper.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/16/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit

class SettingsAboutHelper {
    func tableView(_ tableView: UITableView, cellForRow: Int) -> UITableViewCell {
        let identifier = "AboutCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)
        cell.separatorInset = UIEdgeInsets.init(top: 0, left: 15.0, bottom: 0, right: 0)
        cell.accessoryType = .disclosureIndicator

        switch cellForRow {
        case 0:
            cell.accessoryView = UIImageView.init(image: UIImage.init(systemName: "link"))
            cell.textLabel?.text = "Source Code"
        default:
            cell.textLabel?.text = "Undefined"
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRow: Int, viewController: SettingsViewController) {
        switch didSelectRow {
        case 0:
            UIApplication.shared.open(URL.init(string: "https://github.com/ashtom/hadge")!)
        default: // No op
            break
        }
    }
}
