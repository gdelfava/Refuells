#!/bin/bash

# This script deploys Firestore security rules to your Firebase project

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "   npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in to Firebase
if ! firebase projects:list &> /dev/null; then
    echo "❌ Not logged in to Firebase. Please run:"
    echo "   firebase login"
    exit 1
fi

echo "🚀 Starting Firebase deployment..."

# Deploy Firestore rules
echo "📁 Deploying Firestore security rules..."
firebase deploy --only firestore

echo "✅ Deployment completed!" 