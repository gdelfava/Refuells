//
//  LoginView.swift
//  Refuells
//
//  Created by Guilio Del Fava on 2025/07/01.
//

import SwiftUI
import GoogleSignInSwift
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @StateObject private var firebaseManager = FirebaseManager.shared
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.purple.opacity(0.6),
                    Color.orange.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // App logo and title
                VStack(spacing: 20) {
                    Image(systemName: "fuelpump.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                    
                    Text("Refuells")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Your fuel tracking companion")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Login section
                VStack(spacing: 20) {
                    // Apple Sign In Button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: { result in
                            switch result {
                            case .success(let authorization):
                                if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                    handleAppleSignIn(credential: appleIDCredential)
                                }
                            case .failure(let error):
                                print("❌ Apple Sign-In error: \(error.localizedDescription)")
                                firebaseManager.errorMessage = error.localizedDescription
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 50)
                    .disabled(firebaseManager.isLoading)
                    
                    // Custom Google Sign In Button
                    Button(action: {
                        firebaseManager.signInWithGoogle()
                    }) {
                        HStack {
                            Image(systemName: "globe")
                                .font(.title2)
                            Text("Sign in with Google")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(25)
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .disabled(firebaseManager.isLoading)
                    
                    // Loading indicator
                    if firebaseManager.isLoading {
                        HStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                            Text("Signing in...")
                                .foregroundColor(.white)
                                .font(.subheadline)
                        }
                        .padding(.top, 10)
                    }
                    
                    // Error message
                    if let errorMessage = firebaseManager.errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .padding(.top, 10)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                // Footer
                VStack(spacing: 10) {
                    Text("By signing in, you agree to our")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    HStack(spacing: 20) {
                        Button("Terms of Service") {
                            // Handle terms of service
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        
                        Button("Privacy Policy") {
                            // Handle privacy policy
                        }
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            isAnimating = true
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
    
    private func handleAppleSignIn(credential: ASAuthorizationAppleIDCredential) {
        print("🚀 Starting Apple Sign-In...")
        firebaseManager.isLoading = true
        firebaseManager.errorMessage = nil
        
        guard let appleIDToken = credential.identityToken else {
            let error = "Failed to get Apple ID token"
            print("❌ \(error)")
            firebaseManager.errorMessage = error
            firebaseManager.isLoading = false
            return
        }
        
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            let error = "Failed to convert Apple ID token to string"
            print("❌ \(error)")
            firebaseManager.errorMessage = error
            firebaseManager.isLoading = false
            return
        }
        
        print("✅ Apple ID token obtained, authenticating with Firebase...")
        
        let firebaseCredential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idTokenString,
            rawNonce: ""
        )
        
        Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            DispatchQueue.main.async {
                firebaseManager.isLoading = false
                
                if let error = error {
                    print("❌ Firebase authentication error: \(error.localizedDescription)")
                    firebaseManager.errorMessage = error.localizedDescription
                } else {
                    print("✅ Firebase authentication successful")
                    firebaseManager.checkAuthState()
                }
            }
        }
    }
}

#Preview {
    LoginView()
} 