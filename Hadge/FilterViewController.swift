//
//  FilterViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/7/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

class FilterViewController: UITableViewController {
    var workoutTypes: [HKWorkoutActivityType] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        self.workoutTypes = HKWorkoutActivityType.values
        self.workoutTypes.sort { $0.name < $1.name }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workoutTypes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "FilterCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)

        cell.textLabel?.text = workoutTypes[indexPath.row].name

        return cell
    }

    @IBAction func dismiss(_ sender: Any) {
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
