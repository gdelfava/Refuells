//
//  MenuWrapperView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI

struct MenuWrapperView<Content: View>: View {
    @State private var isMenuShowing = false
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            content
                .environment(\.menuShowing, isMenuShowing)
                .onReceive(NotificationCenter.default.publisher(for: .menuToggle)) { _ in
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isMenuShowing.toggle()
                    }
                }
            
            SlideOverMenuView(isShowing: $isMenuShowing)
        }
    }
}

// Environment key for menu state
private struct MenuShowingKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var menuShowing: Bool {
        get { self[MenuShowingKey.self] }
        set { self[MenuShowingKey.self] = newValue }
    }
}

// Notification for menu toggle
extension Notification.Name {
    static let menuToggle = Notification.Name("menuToggle")
}

// Extension to add menu button to any view
extension View {
    func withMenuButton() -> some View {
        self.toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    NotificationCenter.default.post(name: .menuToggle, object: nil)
                }) {
                    Image(systemName: "line.3.horizontal")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
}

#Preview {
    MenuWrapperView {
        NavigationStack {
            Text("Content")
                .navigationTitle("Test")
        }
    }
} 