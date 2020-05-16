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

class SetupViewController: EntireViewController {
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var stopped = false
    var years: [String: [Any]] = [:]

    @IBOutlet weak var titleView: UITextView!
    @IBOutlet weak var bodyView: UITextView!

    // If the delegate is set, we assume that the controller is used outside the setup flow
    weak var delegate: NSObject?

    override func viewDidLoad() {
        initalizeRepository()

        if delegate != nil {
            self.titleView.text = "Re-upload all data"
        }
    }

    func initalizeRepository() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "InitialExport") {
            self.stopped = true
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        }

        GitHub.shared().getRepository { _ in
            GitHub.shared().updateFile(path: "README.md", content: "This repo is automatically updated by Hadge.", message: "Update README") { _ in
                (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport) { }
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
        let start = Calendar.current.date(from: DateComponents(year: 2014, month: 1, day: 1))
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

    func collectDistanceData(completionHandler: @escaping () -> Swift.Void) {
        let start = Calendar.current.date(from: DateComponents(year: 2014, month: 1, day: 1))
        Health.shared().distanceDataSource?.getAllDistances(start: start!, end: Health.shared().today!) { distances in
            self.initalizeYears()
            distances?.forEach { entry in
                let date = entry["date"] as? String
                self.addDataToYears(String(date!.prefix(4)), data: entry)
            }
            self.exportData(self.years, directory: "distances", contentHandler: { distances in
                return Health.shared().generateContentForDistances(distances: distances)
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

        if delegate != nil {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }

        completionHandler()
    }

    func yearFromDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let yearComponent = calendar.dateComponents([.year], from: date)
        return String(yearComponent.year!)
    }
}
