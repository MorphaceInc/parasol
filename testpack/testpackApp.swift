//
//  testpackApp.swift
//  testpack
//
//  Created by Millie on 2024-10-23.
//

import SwiftUI

@main
struct testpackApp: App {
    // Initializer for the app
    init() {
        // Get App ID
        if let appID = Bundle.main.bundleIdentifier {
            print("App ID: \(appID)")
        }
        
        // Get Device ID
        if let deviceID = UIDevice.current.identifierForVendor?.uuidString {
            print("Device ID: \(deviceID)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
