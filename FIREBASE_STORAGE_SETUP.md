# Firebase Storage Setup for Refuells

This document explains how Firebase Storage has been configured for the Refuells app to handle vehicle images.

## Overview

The app now uses Firebase Storage to store vehicle images instead of local file storage. Images are uploaded to Firebase Storage and the download URLs are stored in Firestore documents.

## Configuration Files

### 1. firebase.json
Updated to include Storage configuration:
```json
{
  "firestore": {
    "rules": "firestore.rules",
    "indexes": "firestore.indexes.json"
  },
  "storage": {
    "rules": "storage.rules"
  }
}
```

### 2. storage.rules
Firebase Storage security rules that allow authenticated users to manage their own vehicle images:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow users to read and write their own vehicle images
    match /users/{userId}/vehicles/{vehicleId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Deny all other access
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## Implementation Details

### Vehicle Model Changes
- Changed `imagePath` property to `imageURL` to store Firebase Storage download URLs
- Updated all initializers and methods to use `imageURL` instead of `imagePath`

### FirebaseManager Extensions
Added two new methods for Firebase Storage operations:

1. **uploadVehicleImage(_:vehicleId:completion:)**
   - Uploads vehicle images to Firebase Storage
   - Stores images in path: `users/{userId}/vehicles/{vehicleId}/vehicle_image.jpg`
   - Returns the download URL for storage in Firestore

2. **deleteVehicleImage(vehicleId:completion:)**
   - Deletes vehicle images from Firebase Storage
   - Used when vehicles are deleted or images are replaced

### VehicleService Updates
- Replaced local file storage methods with Firebase Storage methods
- Added `uploadVehicleImage(_:vehicleId:completion:)` for uploading images
- Added `deleteVehicleImage(vehicleId:completion:)` for deleting images
- Added `loadImageFromURL(_:completion:)` for loading images from URLs

### UI Components
- Created `AsyncImageView` component for efficient image loading from URLs
- Updated `VehicleRowView` and `VehicleDetailView` to use Firebase Storage URLs
- Added proper loading states and error handling

## Deployment

### Deploy Storage Rules
Run the deployment script to deploy Firebase Storage rules:
```bash
./deploy_firebase_storage_rules.sh
```

Or manually deploy:
```bash
firebase deploy --only storage
```

## Usage Flow

### Adding a Vehicle with Image
1. User selects an image in the Add Vehicle form
2. Vehicle is created in Firestore without image URL
3. Image is uploaded to Firebase Storage using the vehicle ID
4. Vehicle document is updated with the image download URL

### Editing a Vehicle Image
1. User selects a new image in the Edit Vehicle form
2. New image is uploaded to Firebase Storage
3. Vehicle document is updated with the new image URL
4. Old image is automatically replaced

### Displaying Images
1. App loads image URLs from Firestore documents
2. `AsyncImageView` component handles loading images from URLs
3. Proper loading states and error handling are displayed

## Security

- Only authenticated users can upload/download images
- Users can only access their own vehicle images
- Images are stored in user-specific paths: `users/{userId}/vehicles/{vehicleId}/`
- All other storage access is denied

## Benefits

1. **Scalability**: Images are stored in the cloud, not on device
2. **Cross-device sync**: Images are available across all user devices
3. **Backup**: Images are automatically backed up with Firebase
4. **Performance**: Images are served via CDN for fast loading
5. **Security**: Proper access controls prevent unauthorized access

## Error Handling

- Network errors during upload/download are handled gracefully
- Invalid URLs are handled with placeholder images
- Loading states provide user feedback
- Failed uploads don't prevent vehicle creation/editing 