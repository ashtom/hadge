//
//  FilterViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/7/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

protocol FilterDelegate: class {
    func onFilterSelected(workoutTypes: [UInt])
}

class FilterViewController: UITableViewController {
    var workoutTypes: [HKWorkoutActivityType] = []
    var checked = [Bool]()
    var preChecked = [UInt]()

    weak var delegate: FilterDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.workoutTypes = HKWorkoutActivityType.values
        self.workoutTypes.sort { $0.name < $1.name }
        self.checked = [Bool](repeating: false, count: self.workoutTypes.count + 1)
        self.preChecked.forEach { index in
            checked[Int(index)] = true
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 2
        case 1:
            return workoutTypes.count
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "FilterCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .default, reuseIdentifier: identifier)

        switch indexPath.section {
        case 0:
            cell.selectionStyle = .gray
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Select all"
            case 1:
                cell.textLabel?.text = "Deselect all"
            default:
                cell.textLabel?.text = nil
            }
        case 1:
            cell.selectionStyle = .none
            cell.textLabel?.text = workoutTypes[indexPath.row].name
            let index = Int(workoutTypes[indexPath.row].rawValue)
            if !checked[index] {
                cell.accessoryType = .none
            } else if checked[index] {
                cell.accessoryType = .checkmark
            }
        default:
            cell.textLabel?.text = nil
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                self.checked = [Bool](repeating: true, count: self.workoutTypes.count + 1)
            case 1:
                self.checked = [Bool](repeating: false, count: self.workoutTypes.count + 1)
            default:
                break
            }
            self.tableView.reloadSections([ 1 ], with: .none)
        case 1:
            if let cell = tableView.cellForRow(at: indexPath) {
                let index = Int(workoutTypes[indexPath.row].rawValue)
                if cell.accessoryType == .checkmark {
                     cell.accessoryType = .none
                     checked[index] = false
                } else {
                     cell.accessoryType = .checkmark
                     checked[index] = true
                }
            }
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    @IBAction func dismiss(_ sender: Any) {
        var active: [UInt] = []
        self.checked.enumerated().forEach { (index, element) in
            if element {
                active.append(UInt(index))
            }
        }

        if active.count == self.workoutTypes.count {
            active = []
        }

        self.delegate?.onFilterSelected(workoutTypes: active)
        self.navigationController!.dismiss(animated: true)
    }
}

extension HKWorkoutActivityType {
    static var values: [Self] {
        var values: [Self] = []
        var index: UInt = 1
        while let element = self.init(rawValue: index) {
            if element.name == "Other" {
                break
            } else {
                values.append(element)
                index += 1
            }
        }
        return values
    }
}
