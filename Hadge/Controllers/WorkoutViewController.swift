import UIKit
import HealthKit

private enum WorkoutSectionType: Int {
    case basic = 0
    case distance
    case heartRate
    case source
}

class WorkoutViewController: EntireTableViewController {
    var workout: HKWorkout?
    var dateFormatter: DateFormatter?
    var timeFormatter: DateFormatter?
    var durationFormatter: DateComponentsFormatter?
    var heartRates: [String: HKQuantity] = [:]

    fileprivate var sections: [WorkoutSectionType] = []
    fileprivate var data: [WorkoutSectionType: [[String?]]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = workout?.workoutActivityType.name

        loadFormatters()
        buildSections()
        loadExtraData()
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
        buildBasicSection()
        if let distance = workout!.totalDistance?.doubleValue(for: HKUnit.meter()), distance > 0 {
            buildDistanceSection(distance)
        }
        buildHeartRateSection()
        buildSourceSection()
    }

    func buildBasicSection() {
        sections.append(.basic)
        data[.basic] = []
        data[.basic]?.append(["Date", dateFormatter?.string(from: workout!.startDate)])
        data[.basic]?.append(["Start", timeFormatter?.string(from: workout!.startDate)])
        data[.basic]?.append(["End", timeFormatter?.string(from: workout!.endDate)])
        data[.basic]?.append(["Duration", durationFormatter?.string(from: workout!.duration)])
        data[.basic]?.append(["Energy burned", String(format: "%.0fcal", workout!.totalEnergyBurned?.doubleValue(for: HKUnit.kilocalorie()) ?? 0)])
    }

    func buildDistanceSection(_ distance: Double) {
        sections.append(.distance)
        data[.distance] = []
        data[.distance]?.append(["Distance", String(format: "%.2fkm", (distance / 1000))])

        if workout!.duration > 0 {
            let paceFormatter = DateComponentsFormatter()
            paceFormatter.unitsStyle = .positional
            paceFormatter.allowedUnits = [ .minute, .second ]
            paceFormatter.zeroFormattingBehavior = [ .pad ]
            data[.distance]?.append(["Speed", String(format: "%.1fkph", distance / workout!.duration * 3.6)])
            data[.distance]?.append(["Pace", paceFormatter.string(from: workout!.duration / distance * 1000)! + "min/km"])
        }

        if let elevation = workout!.metadata?["HKElevationAscended"] as? HKQuantity {
            data[.distance]?.append(["Elevation ascended", String(format: "%.0fm", elevation.doubleValue(for: HKUnit.meter()))])
        }

        if workout!.totalFlightsClimbed != nil {
            data[.distance]?.append(["Flights climbed", String(format: "%.0f", workout!.totalFlightsClimbed?.doubleValue(for: HKUnit.count()) ?? 0)])
        }

        if workout!.workoutActivityType == .swimming {
            data[.distance]?.append(["Swimming strokes", String(format: "%.0f", workout!.totalSwimmingStrokeCount?.doubleValue(for: HKUnit.count()) ?? 0)])
        }
    }

    func buildHeartRateSection() {
        sections.append(.heartRate)
        data[.heartRate] = []
        data[.heartRate]?.append(["Average Heart Rate", heartRateToString(heartRates["average"])])
        data[.heartRate]?.append(["Minimum Heart Rate", heartRateToString(heartRates["minimum"])])
        data[.heartRate]?.append(["Maximum Heart Rate", heartRateToString(heartRates["maximum"])])
    }

    func buildSourceSection() {
        sections.append(.source)
        data[.source] = []
        data[.source]?.append(["Source", workout!.sourceRevision.source.name])
        data[.source]?.append(["Version", workout!.sourceRevision.version ?? "Unknown"])
    }

    func loadExtraData() {
        Health.shared().getHeartRateForWorkout(workout!) { average, minimum, maximum in
            self.heartRates["average"] = average
            self.heartRates["minimum"] = minimum
            self.heartRates["maximum"] = maximum
            self.buildHeartRateSection()
            DispatchQueue.main.async {
                self.tableView.reloadSections([ self.sections.firstIndex(of: .heartRate)! ], with: .none)
            }
        }
    }

    func heartRateToString(_ heartRate: HKQuantity?) -> String {
        guard let heartRate = heartRate else { return "" }
        return String.init(format: "%.0fbpm", heartRate.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
    }
}
