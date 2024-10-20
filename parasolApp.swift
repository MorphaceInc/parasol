//
//  parasolApp.swift
//  parasol
//
//  Created by Jia Xi Chen on 2024-08-27.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct parasolApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Register background task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: "group.com.morphace.parasol.refresh", using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme == "reapplyWidget" {
            if url.host == "open" {
                //  MARK: change to button press
                NotificationCenter.default.post(name: NSNotification.Name("ReapplyButtonPressed"), object: nil)
                return true
            }
        }
        return false
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh()
        
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        
        let operation = BlockOperation {
            let envData = SharedDataManager.shared.getEnvironmentData()
            APIService.shared.fetchTomorrowJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
                switch result {
                case .success(let jsondata):
                    APIService.shared.updateSpfRecm(jsonData: jsondata)
                    APIService.shared.updateUVForecast(jsonData: jsondata)
                case .failure(let error):
                    print(error)
                }
            }
        }
        
        // Expiration handler when task takes too long
        task.expirationHandler = {
            operationQueue.cancelAllOperations()
        }
        
        operation.completionBlock = {
            task.setTaskCompleted(success: !operation.isCancelled)
        }
        
        operationQueue.addOperation(operation)
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: "group.com.morphace.parasol.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to submit background task: \(error)")
        }
    }
}
