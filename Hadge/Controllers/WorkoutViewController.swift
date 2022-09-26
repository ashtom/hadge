import UIKit
import HealthKit
import os.log

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
    var state: [String: Any] = [:]
    var exportSemaphore = false
    var exportButton: UIBarButtonItem!
    var statusLabel: UILabel?

    fileprivate var sections: [WorkoutSectionType] = []
    fileprivate var data: [WorkoutSectionType: [[String?]]] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = workout?.workoutActivityType.name

        restoreState()
        loadFormatters()
        buildSections()
        loadStatusView()
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

    @objc func export(sender: Any) {
        if !exportSemaphore {
            exportSemaphore = true
            updateStatus(string: "Processing workout details...")
            (exportDistances || exportSteps || exportHeartRate || exportLocations || finishExport) {}
        }
    }

    func exportDistances(completionHandler: @escaping () -> Void) {
        if workout?.workoutActivityType == .cycling {
            Health.shared().sampleDataSource?.getAllForWorkout(self.workout!, quantityType: HKQuantityType.quantityType(forIdentifier: .distanceCycling)!) { samples in
                let content = Health.shared().sampleDataSource?.generateContent(samples, quantityName: "Distance Cycling", unit: HKUnit.meter(), format: "%.5f")
                let filename = "\(self.remoteFilePath())/distanceCycling.csv"
                GitHub.shared().updateFile(path: filename, content: content!, message: "Export workout") { _ in
                    self.updateStatus(string: "Distances saved...")
                    completionHandler()
                }
            }
        } else {
            Health.shared().sampleDataSource?.getAllForWorkout(self.workout!, quantityType: HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!) { samples in
                let content = Health.shared().sampleDataSource?.generateContent(samples, quantityName: "Distance Walking/Running", unit: HKUnit.meter(), format: "%.5f")
                let filename = "\(self.remoteFilePath())/distanceWalkingRunning.csv"
                GitHub.shared().updateFile(path: filename, content: content!, message: "Export workout") { _ in
                    self.updateStatus(string: "Distances saved...")
                    completionHandler()
                }
            }
        }
    }

    func exportSteps(completionHandler: @escaping () -> Void) {
        Health.shared().sampleDataSource?.getAllForWorkout(self.workout!, quantityType: HKQuantityType.quantityType(forIdentifier: .stepCount)!) { samples in
            let content = Health.shared().sampleDataSource?.generateContent(samples, quantityName: "Steps", unit: HKUnit.count(), format: "%.0f")
            let filename = "\(self.remoteFilePath())/steps.csv"
            GitHub.shared().updateFile(path: filename, content: content!, message: "Export workout") { _ in
                self.updateStatus(string: "Steps saved...")
                completionHandler()
            }
        }
    }

    func exportHeartRate(completionHandler: @escaping () -> Void) {
        Health.shared().sampleDataSource?.getAllForWorkout(self.workout!, quantityType: HKQuantityType.quantityType(forIdentifier: .heartRate)!) { samples in
            let content = Health.shared().sampleDataSource?.generateContent(samples, quantityName: "Heart Rate", unit: HKUnit.count().unitDivided(by: HKUnit.minute()), format: "%.0f")
            let filename = "\(self.remoteFilePath())/heartRate.csv"
            GitHub.shared().updateFile(path: filename, content: content!, message: "Export workout") { _ in
                self.updateStatus(string: "Heart rates saved...")
                completionHandler()
            }
        }
    }

    func exportLocations(completionHandler: @escaping () -> Void) {
        Health.shared().locationDataSource?.getAllForWorkout(self.workout!) { locations in
            if locations?.count ?? 0 > 0 {
                let content = Health.shared().locationDataSource?.generateContent(locations)
                let filename = "\(self.remoteFilePath())/route.csv"
                GitHub.shared().updateFile(path: filename, content: content!, message: "Export workout") { _ in
                    self.updateStatus(string: "Route saved...")
                    completionHandler()
                }
            } else {
                completionHandler()
            }
        }
    }

    func remoteFilePath() -> String {
        return "workouts/\(self.workout!.workoutActivityType.name.lowercased())/\(self.workout!.uuid.uuidString.lowercased())"
    }

    func finishExport(completionHandler: @escaping () -> Void) {
        state["exported"] = true
        saveState()
        updateButtonState()
        updateStatus(string: "Export finished.")
        clearStatusAfterDelay()

        exportSemaphore = false
        completionHandler()
    }

    func cacheKey() -> String {
        let key = "workout-\(workout!.uuid.uuidString.lowercased())"
        return key
    }

    func restoreState() {
        let cache = NSUbiquitousKeyValueStore()
        self.state = cache.dictionary(forKey: cacheKey()) ?? [:]
        updateButtonState()
        updateStatus(string: "")
    }

    func saveState() {
        // TODO: NSUbiquitousKeyValueStore is limited to 1000 keys / 1MB, so this won't scale forever
        let cache = NSUbiquitousKeyValueStore()
        cache.set(self.state, forKey: cacheKey())
        cache.synchronize()
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
        if self.sections.firstIndex(of: .heartRate) == nil {
            sections.append(.heartRate)
        }
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
            DispatchQueue.main.async {
                self.heartRates["average"] = average
                self.heartRates["minimum"] = minimum
                self.heartRates["maximum"] = maximum
                self.buildHeartRateSection()
                self.tableView.reloadSections([ self.sections.firstIndex(of: .heartRate)! ], with: .none)
            }
        }

        // Split calculation (not finished yet)
        // Health.shared().splitsDataSource?.calculateSplits(workout: workout!)
    }

    func heartRateToString(_ heartRate: HKQuantity?) -> String {
        guard let heartRate = heartRate else { return "" }
        return String.init(format: "%.0fbpm", heartRate.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())))
    }

    func loadStatusView() {
        statusLabel = UILabel(frame: CGRect.init(x: 0, y: 0, width: 200, height: 34))
        statusLabel?.text = ""
        statusLabel?.textAlignment = NSTextAlignment.center
        statusLabel?.textColor = UIColor.secondaryLabel
        statusLabel?.font = UIFont.preferredFont(forTextStyle: .footnote)
        statusLabel?.lineBreakMode = .byWordWrapping
        statusLabel?.numberOfLines = 2

        let statusItem = UIBarButtonItem(customView: statusLabel!)
        exportButton = UIBarButtonItem(image: UIImage(systemName: "plus.app"), style: .plain, target: self, action: #selector(export(sender:)))
        exportButton?.tintColor = UIColor.secondaryLabel
        let leftSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let rightSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        self.toolbarItems = [leftSpaceItem, statusItem, rightSpaceItem, exportButton]

        updateButtonState()

        if let exported = self.state["exported"] as? Bool, exported == true {
        } else {
            updateStatus(string: "Tap the ﹢ button to export this workout's samples to your repo.")
            clearStatusAfterDelay()
        }

    }

    func updateStatus(string: String) {
        DispatchQueue.main.async {
            self.statusLabel?.text = string
        }
    }

    func clearStatusAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !self.exportSemaphore {
                self.updateStatus(string: "")
            }
        }
    }

    func updateButtonState() {
        DispatchQueue.main.async {
            if let exported = self.state["exported"] as? Bool, exported == true {
                self.exportButton.image = UIImage(systemName: "plus.app.fill")
            } else {
                self.exportButton.image = UIImage(systemName: "plus.app")
            }
        }
    }
}
