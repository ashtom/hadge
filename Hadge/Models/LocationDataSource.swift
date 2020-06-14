import UIKit
import CoreLocation
import HealthKit
import SwiftDate
import os.log

class LocationDataSource {
    func getAllForWorkout(_ workout: HKWorkout, completionHandler: @escaping ([CLLocation]?) -> Void) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        let routeQuery = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: predicate, limit: 0, sortDescriptors: [sortDescriptor]) { (_, results, _) in
            guard let routes = results as? [HKWorkoutRoute]?, routes != nil, routes!.count > 0 else {
                completionHandler([])
                return
            }

            var allLocations: [CLLocation] = []
            let locationQuery = HKWorkoutRouteQuery(route: routes!.first!) { (_, locations, done, _) in
                if locations != nil {
                    allLocations += locations!
                }

                if done {
                    completionHandler(allLocations)
                }
            }

            Health.shared().healthStore?.execute(locationQuery)
        }
        Health.shared().healthStore?.execute(routeQuery)
    }

    func generateContent(_ locations: [CLLocation]?) -> String {
        let header = "Date,Latitude,Longitude,Altitude,Speed,Course,Horizontal Accuracy,Vertical Accuracy\n"
        let content: NSMutableString = NSMutableString.init(string: header)
        locations?.forEach { location in
            var components: [String] = []
            components.append(location.timestamp.toISO())
            components.append(String(format: "%.15f", location.coordinate.latitude))
            components.append(String(format: "%.15f", location.coordinate.longitude))
            components.append(String(format: "%.2f", location.altitude))
            components.append(String(format: "%.2f", location.speed))
            components.append(String(format: "%.2f", location.course))
            components.append(String(format: "%.2f", location.horizontalAccuracy))
            components.append(String(format: "%.2f", location.verticalAccuracy))

            content.append(components.joined(separator: ","))
            content.append("\n")
        }
        return String.init(content)
    }
}
