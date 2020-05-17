import UIKit
import HealthKit

class SetupViewController: EntireViewController {
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var stopped = false
    var years: [String: [Any]] = [:]

    @IBOutlet weak var titleView: UITextView!
    @IBOutlet weak var bodyView: UITextView!

    // If the delegate is set, we assume that the controller is used outside the setup flow
    weak var delegate: NSObject?

    override func viewDidLoad() {
        initalizeRepository()

        if delegate != nil {
            self.titleView.text = "Re-upload all data"
        }
    }

    func initalizeRepository() {
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "InitialExport") {
            self.stopped = true
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
        }

        GitHub.shared().getRepository { _ in
            GitHub.shared().updateFile(path: "README.md", content: self.loadReadMeTemplate(), message: "Update README") { _ in
                (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport) { }
            }
        }
    }

    func collectWorkoutData(completionHandler: @escaping () -> Void) {
        Health.shared().getWorkoutsForDates(start: nil, end: nil) { workouts in
            self.initalizeYears()
            workouts?.forEach { workout in
                guard let workout = workout as? HKWorkout else { return }
                self.addDataToYears(self.yearFromDate(workout.startDate), data: workout)
            }
            Health.shared().exportData(self.years, directory: "workouts", contentHandler: { workouts in
                return Health.shared().generateContentForWorkouts(workouts: workouts)
            }, completionHandler: completionHandler)
        }
    }

    func collectActivityData(completionHandler: @escaping () -> Void) {
        let start = Calendar.current.date(from: DateComponents(year: 2014, month: 1, day: 1))
        Health.shared().getActivityDataForDates(start: start, end: Health.shared().yesterday) { summaries in
            self.initalizeYears()
            summaries?.forEach { summary in
                self.addDataToYears(String(summary.dateComponents(for: Calendar.current).year!), data: summary)
            }
            Health.shared().exportData(self.years, directory: "activity", contentHandler: { summaries in
                return Health.shared().generateContentForActivityData(summaries: summaries)
            }, completionHandler: completionHandler)
        }
    }

    func collectDistanceData(completionHandler: @escaping () -> Void) {
        let start = Calendar.current.date(from: DateComponents(year: 2014, month: 1, day: 1))
        Health.shared().distanceDataSource?.getAllDistances(start: start!, end: Health.shared().today!) { distances in
            self.initalizeYears()
            distances?.forEach { entry in
                let date = entry["date"] as? String
                self.addDataToYears(String(date!.prefix(4)), data: entry)
            }
            Health.shared().exportData(self.years, directory: "distances", contentHandler: { distances in
                return Health.shared().generateContentForDistances(distances: distances)
            }, completionHandler: completionHandler)
        }
    }

    func initalizeYears() {
        self.years = [:]
    }

    func addDataToYears(_ year: String, data: Any) {
        years[year] = (years[year] == nil ? [] : years[year])
        years[year]?.append(data)
    }

    func finishExport(completionHandler: @escaping () -> Void) {
        UserDefaults.standard.set(true, forKey: UserDefaultKeys.setupFinished)
        NotificationCenter.default.post(name: .didSetUpRepository, object: nil)
        UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)

        if delegate != nil {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }

        completionHandler()
    }

    func yearFromDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let yearComponent = calendar.dateComponents([.year], from: date)
        return String(yearComponent.year!)
    }

    func loadReadMeTemplate() -> String {
        if let filepath = Bundle.main.path(forResource: "ReadMeTemplate", ofType: "md") {
            do {
                let contents = try String(contentsOfFile: filepath)
                return contents
            } catch {
            }
        } else {
        }

        return "This repo is managed by Hadge."
    }
}
