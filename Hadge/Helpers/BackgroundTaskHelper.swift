import UIKit
import BackgroundTasks
import HealthKit
import os.log

class BackgroundTaskHelper {
    static let sharedInstance = BackgroundTaskHelper()

    var updateActivityData: Bool = false
    var task: BGProcessingTask?

    static func shared() -> BackgroundTaskHelper {
        return sharedInstance
    }

    func registerBackgroundTask() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "io.entire.hadge.bg-fetch", using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                return
            }

            self.handleBackgroundFetchTask(task: processingTask)
        }
    }

    func scheduleBackgroundFetchTask() {
        let request = BGProcessingTaskRequest(identifier: "io.entire.hadge.bg-fetch")
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        do {
            try BGTaskScheduler.shared.submit(request)
            os_log("BG task scheduled.")
        } catch {
            os_log("Error while submitting bg request.")
        }
    }

    func handleBackgroundFetchTask(task: BGProcessingTask) {
        os_log("BG task started")

        self.task = task
        (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport || self.finishBackgroundTask) { }
    }

    func handleForegroundFetch() {
        (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport) { }
    }

    func collectWorkoutData(completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: .isCollectingWorkouts, object: nil)
        Health.shared().getWorkouts { workouts in
            guard let workouts = workouts, workouts.count > 0 else { completionHandler(); return }

            if Health.shared().freshWorkoutsAvailable(workouts: workouts) {
                let content = Health.shared().generateContentForWorkouts(workouts: workouts)
                let filename = "workouts/\(Health.shared().year).csv"
                GitHub.shared().updateFile(path: filename, content: content, message: "Update workouts") { _ in
                    Health.shared().markLastWorkout(workouts: workouts)
                    completionHandler()
                }
            } else {
                completionHandler()
            }
        }
    }

    func collectActivityData(completionHandler: @escaping () -> Void) {
        guard Health.shared().freshActivityAvailable() else { completionHandler(); return }

        self.updateActivityData = true
        NotificationCenter.default.post(name: .collectingActivityData, object: nil)
        Health.shared().getActivityData { summaries in
            guard let summaries = summaries, summaries.count > 0 else { completionHandler(); return }

            let content = Health.shared().generateContentForActivityData(summaries: summaries)
            let filename = "activity/\(Health.shared().year).csv"
            GitHub.shared().updateFile(path: filename, content: content, message: "Update activity") { _ in
                completionHandler()
            }
        }
    }

    func collectDistanceData(completionHandler: @escaping () -> Void) {
        guard self.updateActivityData else { completionHandler(); return }

        NotificationCenter.default.post(name: .collectingDistanceData, object: nil)
        Health.shared().getDistances { distances in
            let content = Health.shared().generateContentForDistances(distances: distances)
            let filename = "distances/\(Health.shared().year).csv"
            GitHub.shared().updateFile(path: filename, content: content, message: "Update distances") { _ in
                Health.shared().markLastDistance(distances: distances!)
                completionHandler()
            }
        }
    }

    func finishExport(completionHandler: @escaping () -> Void) {
        self.updateActivityData = false
        NotificationCenter.default.post(name: .didFinishExport, object: nil)

        Health.shared().getActivityDataForDates(start: Health.shared().today, end: Health.shared().today) { summaries in
            guard let summaries = summaries, summaries.count > 0 else { completionHandler(); return }

            if Constants.debug {
                // When in debug mode, show backhround process via a local notification / app icon badge
                let energy = Int(summaries.last?.activeEnergyBurned.doubleValue(for: .kilocalorie()) ?? 0)
                if self.task != nil {
                    self.sendNotification(energy)
                    completionHandler()
                } else {
                    DispatchQueue.main.async {
                        UIApplication.shared.applicationIconBadgeNumber = energy
                        completionHandler()
                    }
                }
            } else {
                completionHandler()
            }
        }
    }

    func finishBackgroundTask(completionHandler: @escaping () -> Void) {
        self.task?.setTaskCompleted(success: true)
        self.task = nil

        scheduleBackgroundFetchTask()

        os_log("BG task completed")
        completionHandler()
    }

    func sendNotification(_ badge: Int) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "Hadge"
        notificationContent.body = "Total energy burned: \(badge)"
        notificationContent.badge = NSNumber(value: badge)

        let tigger = UNTimeIntervalNotificationTrigger(timeInterval: 10.0, repeats: false)
        let request = UNNotificationRequest(identifier: "Hadge", content: notificationContent, trigger: tigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                os_log("Notification Error: %@", error.localizedDescription)
            }
        }
    }
}
