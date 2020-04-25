//
//  ViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 4/24/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

//        let healthStore = HKHealthStore()
//        let objectTypes: Set<HKObjectType> = [
//            HKObjectType.activitySummaryType()
//        ]
//
//        healthStore.requestAuthorization(toShare: nil, read: objectTypes) { (_, _) in
//            // Do something if the user didn't allow access
//        }
//
//        let calendar = Calendar.autoupdatingCurrent
//        var dateComponents = calendar.dateComponents([ .year, .month, .day ], from: Date())
//        dateComponents.calendar = calendar
//
//        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
//        let query = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, _) in
//            guard let summaries = summaries, summaries.count > 0 else { return }
//            print(summaries.first?.description ?? "")
//        }
//
//        healthStore.execute(query)
    }

}
