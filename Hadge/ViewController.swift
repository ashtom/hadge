//
//  ViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 4/24/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var healthStore: HKHealthStore?
    var data: [[String: Any]] = []

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        healthStore = HKHealthStore()
    }

    override func viewDidAppear(_ animated: Bool) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType()
        ]

        healthStore?.requestAuthorization(toShare: nil, read: objectTypes) { (success, _) in
            if success {
                self.loadData()
            }
        }

        // Debug stuff, will remove later
        //GitHub.shared().getRepository()
        //GitHub.shared().updateFile(path: "README.md", content: "This repo is automatically updated by Hadge.app", message: "Update from Hadge.app")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "DataCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .subtitle, reuseIdentifier: identifier)

        if let title = data[indexPath.row]["title"] as? String? {
            cell.textLabel?.text = title
        }

        return cell
    }

    @IBAction func signOut(_ sender: Any) {
        _ = GitHub.shared().signOut()

        let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
        sceneDelegate?.window?.rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginViewController")
    }

    @IBAction func reload(_ sender: Any) {
        loadData()
    }

    func startRefreshing() {
        DispatchQueue.main.async {
            self.reloadButton.isHidden = true
            self.activityIndicator.startAnimating()
        }
    }

    func stopRefreshing() {
        DispatchQueue.main.async {
            self.reloadButton.isHidden = false
            self.activityIndicator.stopAnimating()
        }
    }

    func loadData() {
        startRefreshing()
        loadActivityData()
        loadWorkouts()
    }

    func loadActivityData() {
        let calendar = Calendar.autoupdatingCurrent
        var dateComponents = calendar.dateComponents([ .year, .month, .day ], from: Date())
        dateComponents.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, _) in
            guard let summaries = summaries, summaries.count > 0 else { return }
            print(summaries.first?.description ?? "")
        }
        healthStore?.execute(activityQuery)
    }

    func loadWorkouts() {
        self.data = []

        let year = Calendar.current.component(.year, from: Date())
        let firstOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))
        let firstOfNextYear = Calendar.current.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        let lastOfYear = Calendar.current.date(byAdding: .day, value: -1, to: firstOfNextYear!)

        let predicate = HKQuery.predicateForSamples(withStart: firstOfYear, end: lastOfYear, options: [])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sampleQuery = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: 0,
            sortDescriptors: [sortDescriptor]) { (_, workouts, _) in
                guard let workouts = workouts, workouts.count > 0 else {
                    self.stopRefreshing()
                    return
                }

                self.createDataFromWorkouts(workouts: workouts)

                let content = self.generateContentForWorkouts(workouts: workouts)
                GitHub.shared().updateFile(path: "workouts/2020.csv", content: content, message: "Update workouts from Hadge.app")
                self.stopRefreshing()
        }
        healthStore?.execute(sampleQuery)
    }

    func createDataFromWorkouts(workouts: [HKSample]) {
        workouts.forEach { workout in
            guard let workout = workout as? HKWorkout else { return }
            data.append([ "title": workout.workoutActivityType.associatedEmojiMale! + " " + workout.workoutActivityType.name ])
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    func generateContentForWorkouts(workouts: [HKSample]) -> String {
        let header = "uuid,start_date,end_date,type,name,duration,distance,energy\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        workouts.reversed().forEach { workout in
            guard let workout = workout as? HKWorkout else { return }
            let line = "\(workout.uuid),\(workout.startDate),\(workout.endDate),\(workout.workoutActivityType.rawValue),\"\(workout.workoutActivityType.name)\",\(workout.duration),\(workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0),\(workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0)\n"
            content.append(line)
        }
        print(content)
        return String.init(content)
    }
}
