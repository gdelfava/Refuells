//
//  KeyboardManager.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import Combine

class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupKeyboardObservers()
    }
    
    private func setupKeyboardObservers() {
        // Keyboard will show
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                let height = keyboardFrame.height
                // Safety check to prevent NaN values
                return height.isFinite && height >= 0 ? height : 0
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.keyboardHeight = height
                self?.isKeyboardVisible = true
            }
            .store(in: &cancellables)
        
        // Keyboard will hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
        
        // Keyboard did show
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .compactMap { notification -> CGFloat? in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return nil
                }
                let height = keyboardFrame.height
                // Safety check to prevent NaN values
                return height.isFinite && height >= 0 ? height : 0
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] height in
                self?.keyboardHeight = height
                self?.isKeyboardVisible = true
            }
            .store(in: &cancellables)
        
        // Keyboard did hide
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidHideNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.keyboardHeight = 0
                self?.isKeyboardVisible = false
            }
            .store(in: &cancellables)
    }
    
    deinit {
        cancellables.removeAll()
    }
}

// SwiftUI View extension for keyboard handling
extension View {
    func keyboardAdaptive() -> some View {
        self.modifier(KeyboardAdaptiveModifier())
    }
}

// Utility extension to prevent NaN values in layout calculations
extension CGFloat {
    var safeValue: CGFloat {
        return self.isFinite && !self.isNaN ? self : 0
    }
}

extension Double {
    var safeValue: CGFloat {
        return self.isFinite && !self.isNaN ? CGFloat(self) : 0
    }
}

struct KeyboardAdaptiveModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.keyboardHeight.safeValue)
            .animation(.easeOut(duration: 0.16), value: keyboardManager.keyboardHeight)
    }
} 