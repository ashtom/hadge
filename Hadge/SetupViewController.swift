//
//  SetupViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/6/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

infix operator >=>: AdditionPrecedence

public typealias Collector = (@escaping () -> Void) -> Void
public func || (first: @escaping Collector, second: @escaping Collector) -> Collector {
    return { combine in
        first {
            second {
                combine()
            }
        }
    }
}

class SetupViewController: UIViewController {
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var stopped = false
    var years: [String: [Any]] = [:]

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
                (self.collectWorkoutData || self.collectActivityData || self.finishExport) { }
            }
        }
    }

    func collectWorkoutData(completionHandler: @escaping () -> Swift.Void) {
        Health.shared().getWorkoutsForDates(start: nil, end: nil) { workouts in
            self.initalizeYears()
            workouts?.forEach { workout in
                guard let workout = workout as? HKWorkout else { return }
                self.addDataToYears(self.yearFromDate(workout.startDate), data: workout)
            }
            self.exportData(self.years, directory: "workouts", contentHandler: { workouts in
                return Health.shared().generateContentForWorkouts(workouts: workouts)
            }, completionHandler: completionHandler)
        }
    }

    func collectActivityData(completionHandler: @escaping () -> Swift.Void) {
        let start = Calendar.current.date(from: DateComponents(year: 2008, month: 1, day: 1))
        Health.shared().getActivityDataForDates(start: start, end: Health.shared().yesterday) { summaries in
            self.initalizeYears()
            summaries?.forEach { summary in
                self.addDataToYears(String(summary.dateComponents(for: Calendar.current).year!), data: summary)
            }
            self.exportData(self.years, directory: "activity", contentHandler: { summaries in
                return Health.shared().generateContentForActivityData(summaries: summaries)
            }, completionHandler: completionHandler)
        }
    }

    func initalizeYears() {
        self.years = [:]
    }

    func addDataToYears(_ year: String, data: Any) {
        years[year] = (years[year] == nil ? [] : years[year])
        years[year]?.append(data)
    }

    func exportData(_ years: [String: [Any]], directory: String, contentHandler: @escaping ([Any]) -> String, completionHandler: @escaping () -> Swift.Void) {
        guard let year = years.first else { completionHandler(); return }
        guard !stopped else { return }

        let content = contentHandler(year.value)
        let filename = "\(directory)/\(year.key).csv"
        GitHub.shared().updateFile(path: filename, content: content, message: "Initial export for \(year.key).") { _ in
            var next = years
            next.removeValue(forKey: year.key)
            self.exportData(next, directory: directory, contentHandler: contentHandler, completionHandler: completionHandler)
        }
    }

    func finishExport(completionHandler: @escaping () -> Swift.Void) {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.setupFinished)
        NotificationCenter.default.post(name: .didSetUpRepository, object: nil)
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)
        completionHandler()
    }

    func yearFromDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let yearComponent = calendar.dateComponents([.year], from: date)
        return String(yearComponent.year!)
    }
}
