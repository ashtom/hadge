//
//  SetupViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/6/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

class SetupViewController: UIViewController {
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var stopped = false

    override func viewDidLoad() {
        initalizeRepository()
    }

    func initalizeRepository() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "InitialExport") {
            self.stopped = true
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        }

        GitHub.shared().getRepository { _ in
            GitHub.shared().updateFile(path: "README.md", content: "This repo is automatically updated by Hadge.app", message: "Update from Hadge.app") { _ in
                self.startExport()
            }
        }
    }

    func startExport() {
        Health.shared().loadWorkoutsForDates(start: nil, end: nil) { workouts in
            var years: [String: [HKSample]] = [:]
            workouts?.reversed().forEach { workout in
                guard let workout = workout as? HKWorkout else { return }

                let calendar = Calendar.current
                let yearComponent = calendar.dateComponents([ .year], from: workout.startDate)
                let year = String(yearComponent.year!)

                years[year] = (years[year] == nil ? [] : years[year])
                years[year]?.append(workout)
            }
            self.exportYears(years)
        }
    }

    func exportYears(_ years: [String: [HKSample]]) {
        guard let year = years.first else { finishExport(); return }
        guard !stopped else { return }

        let content = Health.shared().generateContentForWorkouts(workouts: year.value)
        let filename = "workouts/\(year.key).csv"
        GitHub.shared().updateFile(path: filename, content: content, message: "Initial export for \(year.key).") { _ in
            var next = years
            next.removeValue(forKey: year.key)
            self.exportYears(next)
        }
    }

    func finishExport() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.setupFinished)
        NotificationCenter.default.post(name: .didSetUpRepository, object: nil)

        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)
    }
}
