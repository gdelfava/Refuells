//
//  RefuellsApp.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import Firebase
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Firebase is already configured in the main app
        return true
    }
}

@main
struct RefuellsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var firebaseManager = FirebaseManager.shared
    
    init() {
        FirebaseApp.configure()
        setupKeyboardHandling()
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseManager.isAuthenticated {
                    DashboardView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                firebaseManager.checkAuthState()
            }
            .keyboardAdaptive()
        }
    }
    
    private func setupKeyboardHandling() {
        // Prevent keyboard frame change notifications when keyboard is not present
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillChangeFrameNotification,
            object: nil,
            queue: .main
        ) { notification in
            // Only process if keyboard is actually visible or about to be visible
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                let isKeyboardVisible = keyboardFrame.height > 0
                if !isKeyboardVisible {
                    // Suppress the notification if keyboard is not actually present
                    return
                }
            }
        }
    }
}
