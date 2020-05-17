import HealthKit
import SwiftCSV
import SwiftDate

extension Notification.Name {
    static let didReceiveHealthAccess = Notification.Name("didReceiveHealthAccess")
}

class Health {
    static let sharedInstance = Health()

    var year: Int
    var firstOfYear: Date?
    var lastOfYear: Date?
    var today: Date?
    var yesterday: Date?
    var healthStore: HKHealthStore?
    var distanceDataSource: DistanceDataSource?
    var stopExport: Bool = false

    static func shared() -> Health {
        return sharedInstance
    }

    init() {
        self.healthStore = HKHealthStore()
        self.distanceDataSource = DistanceDataSource()

        let calendar = Calendar.current
        self.year = calendar.component(.year, from: Date())
        self.firstOfYear = Calendar.current.date(from: DateComponents(year: year, month: 1, day: 1))
        self.today = calendar.startOfDay(for: Date.init())
        self.yesterday = Calendar.current.date(byAdding: .day, value: -1, to: self.today!)

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

    func getQuantityForDate(_ quantity: HKQuantityType, date: Date, completionHandler: @escaping (HKQuantity?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: date)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: quantity, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completionHandler(nil)
                return
            }

            completionHandler(sum)
        }

        healthStore?.execute(query)
    }

    func getQuantityForDates(_ quantity: HKQuantityType, start: Date, end: Date, completionHandler: @escaping ([String: HKQuantity]?) -> Void) {
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

            var mapped: [String: HKQuantity] = [:]
            results.enumerateStatistics(from: start, to: end as Date) { statistics, _ in
                if let quantity = statistics.sumQuantity() {
                    let date = statistics.startDate
                    mapped[date.toFormat("yyyy-MM-dd")] = quantity
                }
            }

            completionHandler(mapped)
        }

        healthStore?.execute(query)
    }

    func getActivityData(completionHandler: @escaping ([HKActivitySummary]?) -> Void) {
        getActivityDataForDates(start: firstOfYear, end: yesterday, completionHandler: completionHandler)
    }

    func getActivityDataForDates(start: Date?, end: Date?, completionHandler: @escaping ([HKActivitySummary]?) -> Void) {
        let calendar = Calendar.current
        var startComponents = calendar.dateComponents([ .day, .month, .year], from: start!)
        var endComponents = calendar.dateComponents([ .day, .month, .year], from: end!)

        // Calendar needs to be non-nil, but isn't auto-populated in dateComponents call
        startComponents.calendar = calendar
        endComponents.calendar = calendar

        let predicate = HKQuery.predicate(forActivitySummariesBetweenStart: startComponents, end: endComponents)
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, _) in
            if let summaries = summaries, summaries.count > 0 {
                completionHandler(summaries)
            } else {
                completionHandler([])
            }
        }
        healthStore?.execute(activityQuery)
    }

    func generateContentForActivityData(summaries: [Any]?) -> String {
        let header = "Date,Move Actual,Move Goal,Exercise Actual,Exercise Goal,Stand Actual,Stand Goal\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        let calendar = Calendar.current
        summaries?.forEach { summary in
            guard let summary = summary as? HKActivitySummary else { return }

            let date = Calendar.current.date(from: summary.dateComponents(for: calendar))
            guard date != nil else { return }

            var components: [String] = []
            components.append(date!.toFormat("yyyy-MM-dd"))
            components.append(quantityToString(summary.activeEnergyBurned, unit: HKUnit.kilocalorie()))
            components.append(quantityToString(summary.activeEnergyBurnedGoal, unit: HKUnit.kilocalorie()))
            components.append(quantityToString(summary.appleExerciseTime, unit: HKUnit.minute()))
            components.append(quantityToString(summary.appleExerciseTimeGoal, unit: HKUnit.minute()))
            components.append(quantityToString(summary.appleStandHours, unit: HKUnit.count(), int: true))
            components.append(quantityToString(summary.appleStandHoursGoal, unit: HKUnit.count(), int: true))

            content.append(components.joined(separator: ","))
            content.append("\n")
        }
        return String.init(content)
    }

    func getDistances(completionHandler: @escaping ([[String: Any]]?) -> Void) {
        distanceDataSource?.getAllDistances(start: firstOfYear!, end: today!) { distances in
            completionHandler(distances)
        }
    }

    func generateContentForDistances(distances: [Any]?) -> String {
        let header = "Date,Distance Walking/Running,Steps,Distance Swimming,Strokes,Distance Cycling,Distance Wheelchair,Distance Downhill Snowsports\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        distances?.forEach { entry in
            guard let entry = entry as? [String: Any] else { return }

            var components: [String] = []
            components.append(entry["date"] as? String ?? "")
            components.append(quantityToString(entry["walkingDistance"] as? HKQuantity, unit: HKUnit.meter()))
            components.append(quantityToString(entry["steps"] as? HKQuantity, unit: HKUnit.count()))
            components.append(quantityToString(entry["swimmingDistance"] as? HKQuantity, unit: HKUnit.meter()))
            components.append(quantityToString(entry["strokes"] as? HKQuantity, unit: HKUnit.count()))
            components.append(quantityToString(entry["cyclingDistance"] as? HKQuantity, unit: HKUnit.meter()))
            components.append(quantityToString(entry["wheelchairDistance"] as? HKQuantity, unit: HKUnit.meter()))
            components.append(quantityToString(entry["downhillDistance"] as? HKQuantity, unit: HKUnit.meter()))

            content.append(components.joined(separator: ","))
            content.append("\n")
        }
        return String.init(content)
    }

    func getWorkouts(completionHandler: @escaping ([HKSample]?) -> Void) {
        getWorkoutsForDates(start: firstOfYear, end: lastOfYear, completionHandler: completionHandler)
    }

    func getWorkoutsForDates(start: Date?, end: Date?, completionHandler: @escaping ([HKSample]?) -> Void) {
        let predicate = (start != nil ? HKQuery.predicateForSamples(withStart: start, end: end, options: []) : nil)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: .workoutType(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (_, workouts, _) in
            completionHandler(workouts)
        }
        healthStore?.execute(sampleQuery)
    }

    func generateContentForWorkouts(workouts: [Any]) -> String {
        let header = "UUID,Start Date,End Date,Type,Name,Duration,Distance,Elevation Ascended,Flights Climbed,Swim Strokes,Total Energy\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        workouts.reversed().forEach { workout in
            guard let workout = workout as? HKWorkout else { return }

            var components: [String] = []
            components.append("\(workout.uuid)")
            components.append(workout.startDate.toISO())
            components.append(workout.endDate.toISO())
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

    func freshWorkoutsAvailable(workouts: [HKSample]) -> Bool {
        guard let workout = workouts.first as? HKWorkout else { return false }

        let lastWorkout = UserDefaults.standard.string(forKey: UserDefaultKeys.lastWorkout)
        return lastWorkout == nil || lastWorkout != workout.uuid.uuidString
    }

    func freshActivityAvailable() -> Bool {
        let lastDate = UserDefaults.standard.string(forKey: UserDefaultKeys.lastActivitySyncDate)
        return lastDate == nil || Health.shared().yesterday!.toFormat("yyyy-MM-dd") > lastDate!
    }

    func markLastWorkout(workouts: [HKSample]) {
        guard let workout = workouts.first as? HKWorkout else { return }

        UserDefaults.standard.set(workout.uuid.uuidString, forKey: UserDefaultKeys.lastWorkout)
        UserDefaults.standard.set(Date.init(), forKey: UserDefaultKeys.lastSyncDate)
    }

    func markLastDistance(distances: [[String: Any]]) {
        let lastDate = distances.last?["date"] as? String

        UserDefaults.standard.set(lastDate, forKey: UserDefaultKeys.lastActivitySyncDate)
        UserDefaults.standard.set(Date.init(), forKey: UserDefaultKeys.lastSyncDate)
    }

    func exportData(_ years: [String: [Any]], directory: String, contentHandler: @escaping ([Any]) -> String, completionHandler: @escaping () -> Void) {
        guard let year = years.first else { completionHandler(); return }
        guard !stopExport else { return }

        let content = contentHandler(year.value)
        let filename = "\(directory)/\(year.key).csv"
        GitHub.shared().updateFile(path: filename, content: content, message: "Initial export for \(year.key).") { _ in
            var next = years
            next.removeValue(forKey: year.key)
            self.exportData(next, directory: directory, contentHandler: contentHandler, completionHandler: completionHandler)
        }
    }
}
