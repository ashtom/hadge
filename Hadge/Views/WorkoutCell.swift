import UIKit
import HealthKit

class WorkoutCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var emojiLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var energyLabel: UILabel!
    @IBOutlet weak var sourceLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        emojiLabel.superview?.layer.cornerRadius = 17.0
    }

    func setStartDate(_ date: Date) {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        dateLabel?.text = formatter.localizedString(for: date, relativeTo: Date())
    }

    func setDistance(_ distance: HKQuantity?) {
        let formatter = LengthFormatter()
        formatter.unitStyle = .short
        formatter.numberFormatter.maximumFractionDigits = 1

        if let meters = distance?.doubleValue(for: HKUnit.meter()), meters > 0 {
            distanceLabel?.text = formatter.string(fromValue: meters / 1000, unit: .kilometer)
        } else {
            distanceLabel?.text = ""
        }
    }

    func setDuration(_ duration: TimeInterval) {
        let time = NSInteger(duration)

        let seconds = time % 60
        let minutes = (time / 60) % 60
        let hours = (time / 3600)

        durationLabel?.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }

    func setEnergy(_ energy: HKQuantity?) {
        let calories = energy!.doubleValue(for: HKUnit.kilocalorie())
        energyLabel?.text = String(format: "%0.0fcal", calories)
    }
}
