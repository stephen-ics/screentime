#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

echo "🔍 Checking simulator status..."

# Check if any simulator is currently booted
BOOTED_DEVICE=$(xcrun simctl list devices | grep "Booted" || true)

if [ -z "$BOOTED_DEVICE" ]; then
    echo "📱 No simulator booted. Booting iPhone 16..."
    
    # Get the iPhone 16 device ID
    IPHONE_16_ID=$(xcrun simctl list devices | grep "iPhone 16 (" | head -1 | grep -o "([A-F0-9-]*)" | tr -d "()")
    
    if [ -z "$IPHONE_16_ID" ]; then
        echo "❌ iPhone 16 simulator not found. Creating one..."
        IPHONE_16_ID=$(xcrun simctl create "iPhone 16 Demo" "iPhone 16")
    fi
    
    echo "🚀 Booting iPhone 16 simulator (ID: $IPHONE_16_ID)..."
    xcrun simctl boot "$IPHONE_16_ID"
    
    echo "🖥️ Opening Simulator app..."
    open -a Simulator
    
    # Wait a moment for simulator to fully boot
    echo "⏳ Waiting for simulator to boot completely..."
    sleep 3
else
    echo "✅ Simulator already booted: $BOOTED_DEVICE"
fi

echo "🏗️ Building the project..."
xcodebuild -project screentime.xcodeproj \
           -scheme screentime \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           -derivedDataPath ./build \
           clean build

echo "📱 Installing the app on the booted simulator..."
xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/screentime.app

echo "🚀 Launching the app..."
xcrun simctl launch booted world.screentime

echo "✅ ScreenTime app launched successfully on iPhone demo!"