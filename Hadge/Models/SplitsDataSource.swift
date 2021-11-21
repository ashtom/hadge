import UIKit
import HealthKit
import os.log

class SplitsDataSource {
    func stringFromTimeInterval(_ interval: TimeInterval) -> String {
        let duration = NSInteger(interval)
        let milliseconds = Int(interval.truncatingRemainder(dividingBy: 1) * 1000)
        let seconds = duration % 60
        let minutes = (duration / 60) % 60
        let hours = (duration / 3600)
        return String(format: "%0.2d:%0.2d:%0.2d.%0.3d", hours, minutes, seconds, milliseconds)
    }

    func calculateSplits(workout: HKWorkout) {
        let pauses = getPauses(workout)
        let distanceType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [ .strictStartDate, .strictEndDate ])
//        let predicate = HKQuery.predicateForObjects(from: workout)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: distanceType!, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (_, results, _) in
            if let distanceSamples = results as? [HKQuantitySample], distanceSamples.count > 0 {
                var segmentDistance = 0.00, segmentDuration = 0.00, totalDistance = 0.00
                var segments = 0
                var firstStart = distanceSamples[0].startDate
                var lastEnd = workout.startDate
                var splits: [[String]] = []

                for (index, element) in distanceSamples.enumerated() { // where element.device?.model == "Watch" {
                    let duration = self.getDurationAjustedForPauses(pauses, currentSample: element, lastDate: lastEnd)
                    let distance = element.quantity.doubleValue(for: HKUnit.meter())
                    let speed = distance / duration

                    if duration > 0 {
                        segmentDistance += distance
                        totalDistance += distance
                        segmentDuration += duration
                    }
                    lastEnd = element.endDate

                    if segmentDistance > 1000 {
                        segmentDistance -= 1000
                        let correction = segmentDistance / speed

                        let split = self.stringFromTimeInterval(TimeInterval.init(floatLiteral: segmentDuration - correction))
                        splits.append([String(format: "%.0f", totalDistance / 1000), split])
                        os_log("Full km: %@", split)

                        firstStart = distanceSamples[index].endDate - correction
                        lastEnd = firstStart
                        segmentDuration = correction
                        segments += 1
                    }

                    if (distanceSamples.count - 1 ) == index {
                        let extrapolatedDuration = (segmentDuration / segmentDistance) * 1000
                        let split = self.stringFromTimeInterval(TimeInterval.init(floatLiteral: extrapolatedDuration))
                        splits.append([String(format: "%.0f", totalDistance / 1000), split])
                        os_log("Last: %@", split)
                    }
                }

            }
        }
        Health.shared().healthStore?.execute(query)
    }

    func getPauses(_ workout: HKWorkout) -> [[Date?]] {
        var pauses: [[Date?]] = []
        var current: [Date?] = [nil, nil]
        workout.workoutEvents?.forEach { event in
            if event.type == .pause && current[0] == nil {
                current[0] = event.dateInterval.start
            } else if event.type == .resume && current[0] != nil {
                current[1] = event.dateInterval.end
                pauses.append(current)
                current = [nil, nil]
            }
        }
        return pauses
    }

    func getDurationAjustedForPauses(_ pauses: [[Date?]], currentSample: HKSample, lastDate: Date) -> TimeInterval {
        var duration = currentSample.endDate.timeIntervalSince(lastDate)
        pauses.forEach { pause in
            let pauseStart = pause[0]!
            let pauseEnd = pause[1]!
            if lastDate < pauseStart && currentSample.endDate > pauseEnd {
                duration -= pauseEnd.timeIntervalSince(pauseStart)
            } else if lastDate > pauseStart && currentSample.endDate < pauseEnd {
                duration = 0
            } else if lastDate < pauseStart && currentSample.endDate > pauseStart && currentSample.endDate < pauseEnd {
                duration -= currentSample.endDate.timeIntervalSince(pauseStart)
            } else if lastDate > pauseStart && lastDate < pauseEnd && currentSample.endDate > pauseEnd {
                duration -= pauseEnd.timeIntervalSince(lastDate)
            }
        }
        duration = (duration < 0 ? 0 : duration)
        return duration
    }
}
