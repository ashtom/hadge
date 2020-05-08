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
        self.checked = [Bool](repeating: false, count: self.workoutTypes.count)
        self.workoutTypes.enumerated().forEach { (index, element) in
            if preChecked.firstIndex(of: element.rawValue) != nil {
                checked[index] = true
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "FilterCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .default, reuseIdentifier: identifier)

        cell.textLabel?.text = workoutTypes[indexPath.row].name
        cell.selectionStyle = .none
        if !checked[indexPath.row] {
            cell.accessoryType = .none
        } else if checked[indexPath.row] {
            cell.accessoryType = .checkmark
        }

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            if cell.accessoryType == .checkmark {
                 cell.accessoryType = .none
                 checked[indexPath.row] = false
            } else {
                 cell.accessoryType = .checkmark
                 checked[indexPath.row] = true
            }
        }
    }

    @IBAction func dismiss(_ sender: Any) {
        var active: [UInt] = []
        self.checked.enumerated().forEach { (index, element) in
            if element {
                active.append(self.workoutTypes[index].rawValue)
            }
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
