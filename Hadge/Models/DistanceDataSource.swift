import UIKit
import HealthKit

class DistanceDataSource {
    let dispatchGroup = DispatchGroup()
    var steps: [String: HKQuantity]?
    var strokes: [String: HKQuantity]?
    var cyclingDistances: [String: HKQuantity]?
    var downhillDistances: [String: HKQuantity]?
    var swimmingDistances: [String: HKQuantity]?
    var walkingDistances: [String: HKQuantity]?
    var wheelchairDistances: [String: HKQuantity]?
    var distances = [[String: Any]]()

    func queryDistancesForType(_ quantity: HKQuantityType, start: Date, end: Date, completionHandler: @escaping ([String: HKQuantity]?) -> Void) {
        dispatchGroup.enter()
        Health.shared().getSumQuantityForDates(quantity, start: start, end: end) { statistics in
            completionHandler(statistics)
            self.dispatchGroup.leave()
        }
    }

    func queryDistances(start: Date, end: Date) {
        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .stepCount)!, start: start, end: end) { statistics in
            self.steps = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!, start: start, end: end) { statistics in
            self.strokes = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceCycling)!, start: start, end: end) { statistics in
            self.cyclingDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceDownhillSnowSports)!, start: start, end: end) { statistics in
            self.downhillDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!, start: start, end: end) { statistics in
            self.swimmingDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!, start: start, end: end) { statistics in
            self.walkingDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceWheelchair)!, start: start, end: end) { statistics in
            self.wheelchairDistances = statistics
        }
    }

    func getAllDistances(start: Date, end: Date, completionHandler: @escaping ([[String: Any]]?) -> Void) {
        queryDistances(start: start, end: end)

        dispatchGroup.notify(queue: .main) {
            let currentYear = String(Health.shared().year)
            var firstNonNullFound = false
            Date.enumerateDates(from: start, to: end, increment: DateComponents.create { $0.day = 1 }).forEach { date in
                var entry = [String: Any]()
                let key = date.toFormat("yyyy-MM-dd")
                entry["date"] = key
                entry["steps"] = self.steps?[key]
                entry["strokes"] = self.strokes?[key]
                entry["walkingDistance"] = self.walkingDistances?[key]
                entry["swimmingDistance"] = self.swimmingDistances?[key]
                entry["wheelchairDistance"] = self.wheelchairDistances?[key]
                entry["downhillDistance"] = self.downhillDistances?[key]
                entry["cyclingDistance"] = self.cyclingDistances?[key]

                if firstNonNullFound || key.hasPrefix(currentYear) || self.steps?[key]?.doubleValue(for: .count()) ?? 0.0 > 0.0 {
                    self.distances.append(entry)
                    firstNonNullFound = true
                }
            }

            completionHandler(self.distances.sorted(by: { ($0["date"] as? String)! < ($1["date"] as? String)! }))
        }
    }
}
