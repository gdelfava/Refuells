//
//  KeyboardDebugger.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import Combine

class KeyboardDebugger: ObservableObject {
    @Published var debugInfo: String = ""
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupDebugObservers()
    }
    
    private func setupDebugObservers() {
        let notifications = [
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardDidShowNotification,
            UIResponder.keyboardWillHideNotification,
            UIResponder.keyboardDidHideNotification,
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardDidChangeFrameNotification
        ]
        
        for notification in notifications {
            NotificationCenter.default.publisher(for: notification)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] notification in
                    self?.handleKeyboardNotification(notification)
                }
                .store(in: &cancellables)
        }
    }
    
    private func handleKeyboardNotification(_ notification: Notification) {
        let name = notification.name.rawValue
        let userInfo = notification.userInfo ?? [:]
        
        var info = "📱 Keyboard Event: \(name)\n"
        
        if let frame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            info += "Frame: \(frame)\n"
        }
        
        if let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double {
            info += "Duration: \(duration)\n"
        }
        
        if let curve = userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt {
            info += "Curve: \(curve)\n"
        }
        
        debugInfo = info
        print("🔍 \(info)")
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// Debug view modifier
struct KeyboardDebugModifier: ViewModifier {
    @StateObject private var debugger = KeyboardDebugger()
    
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if !debugger.debugInfo.isEmpty {
                        Text(debugger.debugInfo)
                            .font(.caption)
                            .padding()
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                            .padding()
                    }
                    Spacer()
                }
                .allowsHitTesting(false)
            )
    }
}

extension View {
    func keyboardDebug() -> some View {
        self.modifier(KeyboardDebugModifier())
    }
} 