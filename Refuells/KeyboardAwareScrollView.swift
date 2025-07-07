//
//  KeyboardAwareScrollView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import Combine

struct KeyboardAwareScrollView<Content: View>: View {
    @StateObject private var keyboardManager = KeyboardManager()
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        ScrollView {
            content
                .padding(.bottom, keyboardManager.keyboardHeight.safeValue)
        }
        .animation(.easeOut(duration: 0.16), value: keyboardManager.keyboardHeight)
        .onTapGesture {
            hideKeyboard()
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// Extension to make any view keyboard-aware
extension View {
    func keyboardAware() -> some View {
        self.modifier(KeyboardAwareModifier())
    }
}

struct KeyboardAwareModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.keyboardHeight.safeValue)
            .animation(.easeOut(duration: 0.16), value: keyboardManager.keyboardHeight)
            .onTapGesture {
                hideKeyboard()
            }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
} 