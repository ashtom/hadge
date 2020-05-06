//
//  HealthRequestViewController.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/6/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import UIKit
import HealthKit

class HealthRequestViewController: UIViewController {
    @IBOutlet weak var healthButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        healthButton.layer.cornerRadius = 4
    }

    @IBAction func requestHealthAccess(_ sender: Any) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType(),
            HKQuantityType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!
        ]

        #if targetEnvironment(simulator)
        let samplesTypes: Set<HKSampleType> = [
            HKObjectType.workoutType()
        ]
        #else
        let samplesTypes: Set<HKSampleType> = []
        #endif

        Health.shared().healthStore?.getRequestStatusForAuthorization(toShare: samplesTypes, read: objectTypes) { (status, _) in
            if status == .shouldRequest {
                Health.shared().healthStore?.requestAuthorization(toShare: samplesTypes, read: objectTypes) { (_, _) in
                    NotificationCenter.default.post(name: .didReceiveHealthAccess, object: nil)
                }
            } else {
                DispatchQueue.main.async {
                    UIApplication.shared.open(URL(string: "x-apple-health://")!)
                }
            }
        }
    }
}
