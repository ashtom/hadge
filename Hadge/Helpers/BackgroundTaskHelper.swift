import UIKit
import BackgroundTasks
import os.log

class BackgroundTaskHelper {
    static let sharedInstance = BackgroundTaskHelper()

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

        os_log("BG task executed")
        task.setTaskCompleted(success: true)
    }
}
