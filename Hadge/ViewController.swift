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
    var healthStore: HKHealthStore?

    override func viewDidLoad() {
        super.viewDidLoad()

        healthStore = HKHealthStore()
    }

    override func viewDidAppear(_ animated: Bool) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType()
        ]

        healthStore?.requestAuthorization(toShare: nil, read: objectTypes) { (success, _) in
            if success {
                self.loadData()
            }
        }

        GitHub.shared().getRepository()
    }

    @IBAction func signOut(_ sender: Any) {
        _ = GitHub.shared().signOut()

        let sceneDelegate = self.view.window?.windowScene?.delegate as? SceneDelegate
        sceneDelegate?.window?.rootViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(withIdentifier: "LoginViewController")
    }

    func loadData() {
        let calendar = Calendar.autoupdatingCurrent
        var dateComponents = calendar.dateComponents([ .year, .month, .day ], from: Date())
        dateComponents.calendar = calendar

        let predicate = HKQuery.predicateForActivitySummary(with: dateComponents)
        let activityQuery = HKActivitySummaryQuery(predicate: predicate) { (_, summaries, _) in
            guard let summaries = summaries, summaries.count > 0 else { return }
            print(summaries.first?.description ?? "")
        }
        healthStore?.execute(activityQuery)

        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let sampleQuery = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: nil,
            limit: 0,
            sortDescriptors: [sortDescriptor]) { (_, samples, _) in
            guard let samples = samples, samples.count > 0 else { return }
            print(samples.first?.description ?? "")
        }
        healthStore?.execute(sampleQuery)
    }
}
