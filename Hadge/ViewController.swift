//
//  ViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 4/24/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {
    var healthStore: HKHealthStore?

    @IBOutlet weak var reloadButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

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

    @IBAction func signOut(_ sender: Any) {
        _ = GitHub.shared().signOut()

        let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
        sceneDelegate?.window?.rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginViewController")
    }

    @IBAction func reload(_ sender: Any) {
        loadData()
    }

    func loadData() {
        DispatchQueue.main.async {
            self.reloadButton.isHidden = true
            self.activityIndicator.startAnimating()
        }

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
                guard let workouts = workouts, workouts.count > 0 else { return }
                let content = self.generateContentForWorkouts(workouts: workouts)
                GitHub.shared().updateFile(path: "workouts/2019.csv", content: content, message: "Update workouts from Hadge.app")

                DispatchQueue.main.async {
                    self.reloadButton.isHidden = false
                    self.activityIndicator.stopAnimating()
                }
        }
        healthStore?.execute(sampleQuery)
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
