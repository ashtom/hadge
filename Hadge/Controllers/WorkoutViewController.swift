import UIKit
import HealthKit

class WorkoutViewController: EntireViewController {
    var workout: HKWorkout?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = workout?.workoutActivityType.name
    }
}
