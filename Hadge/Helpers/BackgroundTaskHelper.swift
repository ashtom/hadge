import UIKit
import BackgroundTasks
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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
            os_log("BG task scheduled.")
        } catch {
            os_log("Error while submitting bg request.")
        }
    }

    func handleBackgroundFetchTask(task: BGProcessingTask) {
        scheduleBackgroundFetchTask()
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
        completionHandler()
    }

    func finishBackgroundTask(completionHandler: @escaping () -> Void) {
        self.task?.setTaskCompleted(success: true)
        self.task = nil

        os_log("BG task completed")
        completionHandler()
    }
}
