//
//  DistanceDataSource.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/12/20.
//  Copyright © 2020 Entire. All rights reserved.
//

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

    func queryDistancesForType(_ quantity: HKQuantityType, completionHandler: @escaping ([String: HKQuantity]?) -> Void) {
        dispatchGroup.enter()
        Health.shared().getQuantityForDates(quantity, start: Health.shared().firstOfYear!, end: Health.shared().lastOfYear!) { statistics in
            completionHandler(statistics)
            self.dispatchGroup.leave()
        }
    }

    func queryDistances() {
        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .stepCount)!) { statistics in
            self.steps = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .swimmingStrokeCount)!) { statistics in
            self.strokes = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceCycling)!) { statistics in
            self.cyclingDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceDownhillSnowSports)!) { statistics in
            self.downhillDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!) { statistics in
            self.swimmingDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!) { statistics in
            self.walkingDistances = statistics
        }

        queryDistancesForType(HKQuantityType.quantityType(forIdentifier: .distanceWheelchair)!) { statistics in
            self.wheelchairDistances = statistics
        }
    }

    func getAllDistances(completionHandler: @escaping ([[String: Any]]?) -> Void) {
        queryDistances()

        dispatchGroup.notify(queue: .main) {
            Date.enumerateDates(from: Health.shared().firstOfYear!, to: Health.shared().today!, increment: DateComponents.create { $0.day = 1 }).forEach { date in
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
                self.distances.append(entry)
            }

            completionHandler(self.distances.sorted(by: { ($0["date"] as? String)! < ($1["date"] as? String)! }))
        }
    }
}
