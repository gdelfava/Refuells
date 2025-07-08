#!/bin/bash

# Deploy Firebase Storage Rules
echo "🚀 Deploying Firebase Storage Rules..."

# Check if firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI is not installed. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Deploy storage rules
firebase deploy --only storage

echo "✅ Firebase Storage Rules deployed successfully!" 