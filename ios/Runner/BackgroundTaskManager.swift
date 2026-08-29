import Foundation
import BackgroundTasks

class BackgroundTaskManager {
    
    static let shared = BackgroundTaskManager()
    
    func registerBackgroundTasks() {
        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(
                forTaskWithIdentifier: "com.goldenfeather.eld.tracking",
                using: nil
            ) { task in
                self.handleTrackingTask(task: task as! BGProcessingTask)
            }
        }
    }
    
    @available(iOS 13.0, *)
    private func handleTrackingTask(task: BGProcessingTask) {
        // استمرار التتبع في الخلفية
        task.setTaskCompleted(success: true)
    }
}
