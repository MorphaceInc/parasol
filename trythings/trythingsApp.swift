//
//  trythingsApp.swift
//  trythings
//
//  Created by Millie on 2024-09-05.
//

import SwiftUI

@main
struct trythingsApp: App {
    @StateObject var videoManager = VideoManager() // Use @StateObject to own the instance
    var body: some Scene {
        WindowGroup {
            ContentView(videoManager: videoManager)
        }
    }
}
