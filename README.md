# Refuells - Fuel Tracking App

A modern iOS app for tracking fuel consumption and vehicle maintenance with Firebase authentication.

## Features

- 🔐 **Google Sign-In Authentication** - Secure login using Google accounts
- 📊 **Dashboard** - View fuel statistics and recent activity
- 🎨 **Modern UI** - Beautiful gradient design with smooth animations
- 📱 **iOS Native** - Built with SwiftUI for optimal performance

## Setup Instructions

### 1. Firebase Configuration

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select an existing one
3. Add an iOS app to your Firebase project:
   - Bundle ID: `com.yourcompany.Refuells`
   - App nickname: `Refuells`
4. Download the `GoogleService-Info.plist` file
5. Add the file to your Xcode project (drag and drop into the project navigator)

### 2. Google Sign-In Setup

1. In Firebase Console, go to Authentication > Sign-in method
2. Enable Google Sign-in
3. Add your iOS app's bundle ID to the authorized domains

### 3. Xcode Project Configuration

1. Open your project in Xcode
2. Add the following dependencies via Swift Package Manager:
   - `https://github.com/firebase/firebase-ios-sdk.git`
   - `https://github.com/google/GoogleSignIn-iOS.git`

3. Select these packages:
   - FirebaseAuth
   - FirebaseFirestore
   - GoogleSignIn
   - GoogleSignInSwift

### 4. URL Scheme Configuration

1. In Xcode, select your project target
2. Go to Info tab
3. Add a new URL scheme:
   - Key: `CFBundleURLTypes`
   - Type: Array
   - Add item with:
     - URL Schemes: `com.googleusercontent.apps.YOUR_CLIENT_ID`
     - URL identifier: `REVERSED_CLIENT_ID`

### 5. Build and Run

1. Clean build folder (Cmd + Shift + K)
2. Build and run the project (Cmd + R)

## Project Structure

```
Refuells/
├── RefuellsApp.swift          # Main app entry point
├── FirebaseManager.swift       # Firebase authentication manager
├── LoginView.swift            # Beautiful login screen
├── DashboardView.swift        # Main dashboard after login
└── ContentView.swift          # Original content view (can be removed)
```

## Key Components

### FirebaseManager
- Handles Google Sign-In authentication
- Manages user session state
- Provides sign-out functionality
- Error handling and loading states

### LoginView
- Modern gradient background
- Animated fuel pump icon
- Google Sign-In button
- Loading indicators and error messages
- Terms of service links

### DashboardView
- Welcome message with user name
- Fuel statistics cards
- Recent activity feed
- Sign-out functionality

## Authentication Flow

1. App starts and checks authentication state
2. If not authenticated, shows LoginView
3. User taps Google Sign-In button
4. Google Sign-In flow completes
5. Firebase creates/updates user account
6. App shows DashboardView
7. User can sign out to return to LoginView

## Customization

### Colors and Styling
- Modify the gradient colors in `LoginView.swift`
- Update card colors in `DashboardView.swift`
- Customize fonts and spacing throughout

### Firebase Features
- Add Firestore for data persistence
- Implement user profile management
- Add push notifications
- Enable analytics

## Troubleshooting

### Common Issues

1. **"Firebase configuration error"**
   - Ensure `GoogleService-Info.plist` is added to the project
   - Check that the bundle ID matches Firebase configuration

2. **"Unable to present sign-in view"**
   - Verify URL scheme configuration
   - Check that Google Sign-In is enabled in Firebase Console

3. **Build errors with dependencies**
   - Clean build folder and rebuild
   - Ensure all Firebase packages are properly linked

### Debug Tips

- Check Firebase Console for authentication logs
- Use Xcode console to view debug messages
- Verify network connectivity for Google Sign-In

## Next Steps

1. Add Firestore database for storing fuel data
2. Implement fuel entry forms
3. Add charts and analytics
4. Enable push notifications
5. Add offline support
6. Implement data export features

## Requirements

- iOS 15.0+
- Xcode 14.0+
- Swift 5.9+
- Firebase project with Google Sign-In enabled

## License

This project is for educational purposes. Please ensure compliance with Firebase and Google Sign-In terms of service. 