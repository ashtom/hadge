//
//  Health.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/2/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import HealthKit
import SwiftCSV

extension Notification.Name {
    static let didReceiveHealthAccess = Notification.Name("didReceiveHealthAccess")
}

class Health {
    static let sharedInstance = Health()

    var year: Int
    var firstOfYear: Date?
    var lastOfYear: Date?
    var healthStore: HKHealthStore?

    static func shared() -> Health {
        return sharedInstance
    }

    init() {
        self.healthStore = HKHealthStore()

        let calendar = Calendar.current
        self.year = calendar.component(.year, from: Date())
        self.firstOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))

        let firstOfNextYear = Calendar.current.date(from: DateComponents(year: year + 1, month: 1, day: 1))
        self.lastOfYear = Calendar.current.date(byAdding: .day, value: -1, to: firstOfNextYear!)
    }

    func getBiologicalSex() -> HKBiologicalSexObject? {
        var biologicalSex: HKBiologicalSexObject?
        do {
            try biologicalSex = self.healthStore?.biologicalSex()
            return biologicalSex
        } catch {
            return nil
        }
    }

    func loadActivityData(completionHandler: @escaping ([HKActivitySummary]?) -> Swift.Void) {
        loadActivityDataForDates(start: Health().firstOfYear, end: Health().lastOfYear, completionHandler: completionHandler)
    }

    func loadActivityDataForDates(start: Date?, end: Date?, completionHandler: @escaping ([HKActivitySummary]?) -> Swift.Void) {
        let calendar = Calendar.current
        var firstOfYear = calendar.dateComponents([ .day, .month, .year], from: start!)
        var lastOfYear = calendar.dateComponents([ .day, .month, .year], from: end!)

        // Calendar needs to be non-nil, but isn't auto-populated in dateComponents call
        firstOfYear.calendar = calendar
        lastOfYear.calendar = calendar

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: firstOfYear, end: lastOfYear)
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, _) in
            if let summaries = summaries, summaries.count > 0 {
                completionHandler(summaries)
            } else {
                completionHandler([])
            }
        }
        healthStore?.execute(activityQuery)
    }

    func loadWorkouts(completionHandler: @escaping ([HKSample]?) -> Swift.Void) {
        loadWorkoutsForDates(start: Health().firstOfYear, end: Health().lastOfYear, completionHandler: completionHandler)
    }

    func loadWorkoutsForDates(start: Date?, end: Date?, completionHandler: @escaping ([HKSample]?) -> Swift.Void) {
        let predicate = (start != nil ? HKQuery.predicateForSamples(withStart: start, end: end, options: []) : nil)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (_, workouts, _) in
            completionHandler(workouts)
        }
        healthStore?.execute(sampleQuery)
    }

    func generateContentForWorkouts(workouts: [HKSample]) -> String {
        let header = "UUID,Start Date,End Date,Type,Name,Duration,Distance,Elevation Ascended,Flights Climbed,Swim Strokes,Total Energy\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        workouts.reversed().forEach { workout in
            guard let workout = workout as? HKWorkout else { return }

            var components: [String] = []
            components.append("\(workout.uuid)")
            components.append("\(workout.startDate)")
            components.append("\(workout.endDate)")
            components.append("\(workout.workoutActivityType.rawValue)")
            components.append(workout.workoutActivityType.name)
            components.append("\(workout.duration)")
            components.append("\(workout.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0)")

            if let elevation = workout.metadata?["HKElevationAscended"] as? HKQuantity {
                components.append("\(elevation.doubleValue(for: HKUnit.meter()))")
            } else {
                components.append("")
            }

            components.append("\(workout.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) ?? 0)")
            components.append("\(workout.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count()) ?? 0)")
            components.append("\(workout.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0)")

            content.append(components.joined(separator: ","))
            content.append("\n")
        }
        return String.init(content)
    }
}
