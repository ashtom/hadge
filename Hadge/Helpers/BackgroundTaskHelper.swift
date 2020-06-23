import UIKit
import BackgroundTasks
import HealthKit
import os.log

class BackgroundTaskHelper {
    static let sharedInstance = BackgroundTaskHelper()

    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier?
    var updateActivityData: Bool = false
    var stopped: Bool = false
    var workoutQueryInitialized: Bool = false
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
        request.earliestBeginDate = Date(timeIntervalSinceNow: 3600)
        do {
            try BGTaskScheduler.shared.submit(request)
            os_log("BG task scheduled.")
        } catch {
            os_log("Error while submitting bg request.")
        }
    }

    func registerBackgroundDelivery() {
        scheduleStepsQuery()
        scheduleWorkoutQuery()
    }

    func scheduleStepsQuery() {
        if Constants.debug {
            let stepQuery = HKObserverQuery(sampleType: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, predicate: nil, updateHandler: { _, completionHandler, error in
                guard error == nil else { completionHandler(); return }
                Health.shared().getSumQuantityForDate(HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, date: Date.init()) { quantity in
                    if quantity != nil {
                        self.sendNotification(Int(quantity!.doubleValue(for: HKUnit.count())))
                    }
                    completionHandler()
                }
            })
            Health.shared().healthStore?.execute(stepQuery)
            Health.shared().healthStore?.enableBackgroundDelivery(for: HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!, frequency: .hourly, withCompletion: { succeeded, error in
                if error == nil && succeeded {
                    os_log("Background delivery enabled for steps")
                } else {
                    os_log("Failed to enable background delivery for steps")
                }
            })
        }
    }

    func scheduleWorkoutQuery() {
        let workoutQuery = HKObserverQuery(sampleType: HKObjectType.workoutType(), predicate: nil, updateHandler: { _, completionHandler, error in
            defer {
                completionHandler()
            }

            if !self.workoutQueryInitialized {
                self.workoutQueryInitialized = true
            } else if error == nil && self.backgroundTaskIdentifier == nil {
                self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "WorkoutExport") {
                    self.stopped = true
                    UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier!)
                }

                self.handleForegroundFetch()
            }
        })
        Health.shared().healthStore?.execute(workoutQuery)
        Health.shared().healthStore?.enableBackgroundDelivery(for: HKObjectType.workoutType(), frequency: .immediate, withCompletion: { succeeded, error in
            if error == nil && succeeded {
                os_log("Background delivery enabled for workouts")
            } else {
                os_log("Failed to enable background delivery for workouts")
            }
        })
    }

    func handleBackgroundFetchTask(task: BGProcessingTask) {
        self.task = task
        self.stopped = false
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished) && UIApplication.shared.isProtectedDataAvailable {
            (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport || self.finishBackgroundTask) { }
        } else {
            self.finishBackgroundTask { }
        }
    }

    func handleForegroundFetch() {
        self.stopped = false
        if UserDefaults.standard.bool(forKey: UserDefaultKeys.setupFinished) {
            (self.collectWorkoutData || self.collectActivityData || self.collectDistanceData || self.finishExport) { }
        }
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
        guard Health.shared().freshActivityAvailable() && !stopped else { completionHandler(); return }

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
        guard self.updateActivityData && !stopped else { completionHandler(); return }

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

        if backgroundTaskIdentifier != nil {
            UIApplication.shared.endBackgroundTask(backgroundTaskIdentifier!)
            self.backgroundTaskIdentifier = nil
        }

        completionHandler()
    }

    func finishBackgroundTask(completionHandler: @escaping () -> Void) {
        self.task?.setTaskCompleted(success: true)
        self.task = nil

        scheduleBackgroundFetchTask()
        completionHandler()
    }

    func sendNotification(_ badge: Int) {
        let notificationContent = UNMutableNotificationContent()
        //notificationContent.title = "Hadge"
        //notificationContent.body = "Steps walked: \(badge)"
        notificationContent.badge = NSNumber(value: badge)

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10.0, repeats: false)
        let request = UNNotificationRequest(identifier: "Hadge", content: notificationContent, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                os_log("Notification Error: %@", error.localizedDescription)
            }
        }

        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = badge
        }
    }
}
