import UIKit
import HealthKit

class WorkoutViewController: EntireTableViewController {
    var workout: HKWorkout?
    var dateFormatter: DateFormatter?
    var timeFormatter: DateFormatter?
    var durationFormatter: DateComponentsFormatter?

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = workout?.workoutActivityType.name

        self.dateFormatter = DateFormatter()
        self.dateFormatter?.timeStyle = .none
        self.dateFormatter?.dateStyle = .long

        self.timeFormatter = DateFormatter()
        self.timeFormatter?.timeStyle = .medium
        self.timeFormatter?.dateStyle = .none

        self.durationFormatter = DateComponentsFormatter()
        self.durationFormatter?.unitsStyle = .positional
        self.durationFormatter?.allowedUnits = [ .hour, .minute, .second ]
        self.durationFormatter?.zeroFormattingBehavior = [ .pad ]
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 9
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "DetailCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .value1, reuseIdentifier: identifier)
        cell.selectionStyle = .none

        switch indexPath.row {
        case 0:
            cell.textLabel?.text = "Date"
            cell.detailTextLabel?.text = dateFormatter?.string(from: workout!.startDate)
        case 1:
            cell.textLabel?.text = "Start"
            cell.detailTextLabel?.text = timeFormatter?.string(from: workout!.startDate)
        case 2:
            cell.textLabel?.text = "End"
            cell.detailTextLabel?.text = timeFormatter?.string(from: workout!.endDate)
        case 3:
            cell.textLabel?.text = "Duration"
            cell.detailTextLabel?.text = durationFormatter?.string(from: workout!.duration)
        case 4:
            cell.textLabel?.text = "Energy burned"
            cell.detailTextLabel?.text = String(format: "%.0fcal", workout!.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0)
        case 5:
            cell.textLabel?.text = "Distance"
            cell.detailTextLabel?.text = String(format: "%.2fkm", (workout!.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0) / 1000)
        case 6:
            cell.textLabel?.text = "Flights climbed"
            cell.detailTextLabel?.text = String(format: "%.0f", workout!.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) ?? 0)
        case 7:
            cell.textLabel?.text = "Swimming strokes"
            cell.detailTextLabel?.text = String(format: "%.0f", workout!.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count()) ?? 0)
        case 8:
            cell.textLabel?.text = "Source"
            cell.detailTextLabel?.text = workout!.sourceRevision.source.name
        default:
            break
        }
        return cell
    }
}
