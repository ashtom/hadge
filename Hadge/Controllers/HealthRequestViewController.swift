import UIKit
import HealthKit

class HealthRequestViewController: EntireViewController {
    @IBOutlet weak var healthButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        healthButton.layer.cornerRadius = 4

        for subView in self.view.subviews where subView is UITextView {
            guard let textView = subView as? UITextView else { continue }
            textView.textContainerInset = UIEdgeInsets.init(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    @IBAction func requestHealthAccess(_ sender: Any) {
        let objectTypes: Set<HKObjectType> = [
            HKObjectType.activitySummaryType(),
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceCycling)!,
            HKObjectType.quantityType(forIdentifier: .distanceDownhillSnowSports)!,
            HKObjectType.quantityType(forIdentifier: .distanceSwimming)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.quantityType(forIdentifier: .distanceWheelchair)!,
            HKObjectType.quantityType(forIdentifier: .flightsClimbed)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .swimmingStrokeCount)!,
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
