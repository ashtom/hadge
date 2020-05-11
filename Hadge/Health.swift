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

    func getQuantityForDate(_ quantity: HKQuantityType, unit: HKUnit, date: Date, completionHandler: @escaping (Double) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantity, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completionHandler(0.0)
                return
            }

            completionHandler(sum.doubleValue(for: unit))
        }

        healthStore?.execute(query)
    }

    func getQuantityForDates(_ quantity: HKQuantityType, unit: HKUnit, start: Date, end: Date, completionHandler: @escaping (HKStatistics?) -> Void) {
        let calendar = NSCalendar.current
        let interval = NSDateComponents()
        interval.day = 1

        let anchorComponents = calendar.dateComponents([.day, .month, .year], from: NSDate() as Date)
        let anchorDate = calendar.date(from: anchorComponents)

        let query = HKStatisticsCollectionQuery(quantityType: quantity, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: anchorDate!, intervalComponents: interval as DateComponents)
        query.initialResultsHandler = {query, results, error in
            guard let results = results else {
                completionHandler(nil)
                return
            }

            results.enumerateStatistics(from: start, to: end as Date) { statistics, _ in
                completionHandler(statistics)
            }
        }

        healthStore?.execute(query)
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
            components.append(String(format: "%.3f", workout.duration))
            components.append(quantityToString(workout.totalDistance, unit: HKUnit.meter()))

            if let elevation = workout.metadata?["HKElevationAscended"] as? HKQuantity {
                components.append(quantityToString(elevation, unit: HKUnit.meter()))
            } else {
                components.append("0")
            }

            components.append(quantityToString(workout.totalFlightsClimbed, unit: HKUnit.count(), int: true))
            components.append(quantityToString(workout.totalSwimmingStrokeCount, unit: HKUnit.count(), int: true))
            components.append(quantityToString(workout.totalEnergyBurned, unit: HKUnit.kilocalorie()))

            content.append(components.joined(separator: ","))
            content.append("\n")
        }
        return String.init(content)
    }

    func quantityToString(_ quantity: HKQuantity?, unit: HKUnit, int: Bool = false) -> String {
        return String(format: (int ? "%.0f" : "%.2f"), quantity?.doubleValue(for: unit) ?? 0)
    }
}
