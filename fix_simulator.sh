#!/bin/bash

# Fix iOS Simulator Issues Script
# This script helps resolve common iOS simulator problems

echo "🔧 Fixing iOS Simulator Issues..."

# Get the booted simulator device ID
BOOTED_DEVICE=$(xcrun simctl list devices | grep "Booted" | head -1 | sed 's/.*(\([^)]*\)).*/\1/')

if [ -z "$BOOTED_DEVICE" ]; then
    echo "❌ No booted simulator found"
    exit 1
fi

echo "📱 Found booted device: $BOOTED_DEVICE"

# Shutdown the simulator
echo "🔄 Shutting down simulator..."
xcrun simctl shutdown "$BOOTED_DEVICE"

# Erase the simulator
echo "🧹 Erasing simulator data..."
xcrun simctl erase "$BOOTED_DEVICE"

# Boot the simulator
echo "🚀 Booting simulator..."
xcrun simctl boot "$BOOTED_DEVICE"

echo "✅ Simulator reset complete!"
echo "💡 You can now run your app again" 