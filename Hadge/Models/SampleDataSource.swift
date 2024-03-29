import UIKit
import HealthKit
import SwiftDate
import os.log

class SampleDataSource {
    func getAllForWorkout(_ workout: HKWorkout, quantityType: HKQuantityType, completionHandler: @escaping ([HKQuantitySample]?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [ .strictStartDate, .strictEndDate ])
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let query = HKSampleQuery(sampleType: quantityType, predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (_, results, _) in
            if let samples = results as? [HKQuantitySample], samples.count > 0 {
                completionHandler(samples)
            } else {
                completionHandler([])
            }
        }
        Health.shared().healthStore?.execute(query)
    }

    func generateContent(_ samples: [HKQuantitySample]?, quantityName: String, unit: HKUnit, format: String?) -> String {
        let header = "Start Date,End Date,\(quantityName),Source,Device\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        samples?.forEach { sample in
            var components: [String] = []
            components.append(sample.startDate.toISO())
            components.append(sample.endDate.toISO())
            if format != nil {
                components.append(String(format: format!, sample.quantity.doubleValue(for: unit)))
            } else {
                components.append(String(format: "%.5f", sample.quantity.doubleValue(for: unit)))
            }
            components.append(sample.sourceRevision.source.name)
            components.append(sample.device?.name ?? "")

            content.append(components.joined(separator: ","))
            content.append("\n")
        }
        return String.init(content)
    }
}
