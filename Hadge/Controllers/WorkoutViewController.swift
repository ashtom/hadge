import UIKit
import HealthKit

private enum WorkoutSectionType: Int {
    case basic = 0
    case distance
    case source
}

class WorkoutViewController: EntireTableViewController {
    var workout: HKWorkout?
    var dateFormatter: DateFormatter?
    var timeFormatter: DateFormatter?
    var durationFormatter: DateComponentsFormatter?

    fileprivate var sections: [WorkoutSectionType] = []
    fileprivate var data: [WorkoutSectionType: [[String?]]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = workout?.workoutActivityType.name

        loadFormatters()
        buildSections()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = sections[section]
        return data[sectionType]?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "DetailCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? UITableViewCell.init(style: .value1, reuseIdentifier: identifier)
        cell.selectionStyle = .none

        let sectionType = sections[indexPath.section]
        let row = data[sectionType]?[indexPath.row]
        cell.textLabel?.text = row?[0]
        cell.detailTextLabel?.text = row?[1]

        return cell
    }

    func loadFormatters() {
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

    func buildSections() {
        sections.append(.basic)
        data[.basic] = []
        data[.basic]?.append(["Date", dateFormatter?.string(from: workout!.startDate)])
        data[.basic]?.append(["Start", timeFormatter?.string(from: workout!.startDate)])
        data[.basic]?.append(["End", timeFormatter?.string(from: workout!.endDate)])
        data[.basic]?.append(["Duration", durationFormatter?.string(from: workout!.duration)])
        data[.basic]?.append(["Energy burned", String(format: "%.0fcal", workout!.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0)])

        sections.append(.distance)
        data[.distance] = []
        data[.distance]?.append(["Distance", String(format: "%.2fkm", (workout!.totalDistance?.doubleValue(for: HKUnit.meter()) ?? 0) / 1000)])
        data[.distance]?.append(["Flights climbed", String(format: "%.0f", workout!.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) ?? 0)])
        data[.distance]?.append(["Swimming strokes", String(format: "%.0f", workout!.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count()) ?? 0)])

        sections.append(.source)
        data[.source] = []
        data[.source]?.append(["Source", workout!.sourceRevision.source.name])
        data[.source]?.append(["Version", workout!.sourceRevision.version ?? "Unknown"])
    }
}
