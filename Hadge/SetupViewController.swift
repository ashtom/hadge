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
            GitHub.shared().updateFile(path: "README.md", content: "This repo is automatically updated by Hadge.", message: "Update README") { _ in
                self.collectWorkoutData()
            }
        }
    }

    func collectWorkoutData() {
        Health.shared().getWorkoutsForDates(start: nil, end: nil) { workouts in
            var years: [String: [HKSample]] = [:]
            workouts?.forEach { workout in
                guard let workout = workout as? HKWorkout else { return }

                let year = self.yearFromDate(workout.startDate)
                years[year] = (years[year] == nil ? [] : years[year])
                years[year]?.append(workout)
            }
            self.exportWorkouts(years)
        }
    }

    func exportWorkouts(_ years: [String: [HKSample]]) {
        guard let year = years.first else { collectActivityData(); return }
        guard !stopped else { return }

        let content = Health.shared().generateContentForWorkouts(workouts: year.value)
        let filename = "workouts/\(year.key).csv"
        GitHub.shared().updateFile(path: filename, content: content, message: "Initial export for \(year.key).") { _ in
            var next = years
            next.removeValue(forKey: year.key)
            self.exportWorkouts(next)
        }
    }

    func collectActivityData() {
        let start = Calendar.current.date(from: DateComponents(year: 2008, month: 1, day: 1))
        Health.shared().getActivityDataForDates(start: start, end: Health.shared().yesterday) { summaries in
            var years: [String: [HKActivitySummary]] = [:]
            summaries?.forEach { summary in
                let year = String(summary.dateComponents(for: Calendar.current).year!)
                years[year] = (years[year] == nil ? [] : years[year])
                years[year]?.append(summary)
            }
            self.exportActivity(years)
        }
    }

    func exportActivity(_ years: [String: [HKActivitySummary]]) {
        guard let year = years.first else { finishExport(); return }
        guard !stopped else { return }

        let content = Health.shared().generateContentForActivityData(summaries: year.value)
        let filename = "activity/\(year.key).csv"
        GitHub.shared().updateFile(path: filename, content: content, message: "Initial export for \(year.key).") { _ in
            var next = years
            next.removeValue(forKey: year.key)
            self.exportActivity(next)
        }
    }

    func finishExport() {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.setupFinished)
        NotificationCenter.default.post(name: .didSetUpRepository, object: nil)

        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)
    }

    func yearFromDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let yearComponent = calendar.dateComponents([.year], from: date)
        return String(yearComponent.year!)
    }
}
