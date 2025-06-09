#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

# Parse command line arguments
INSTANCES=1
if [ "$1" = "--dual" ] || [ "$1" = "-d" ]; then
    INSTANCES=2
elif [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [--dual|-d] [--help|-h]"
    echo "  --dual, -d    Launch two simulator instances"
    echo "  --help, -h    Show this help message"
    exit 0
fi

echo "🏗️ Building the project..."
xcodebuild -project screentime.xcodeproj \
           -scheme screentime \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           -derivedDataPath ./build \
           clean build

if [ $INSTANCES -eq 1 ]; then
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
    
    echo "📱 Installing the app on the booted simulator..."
    xcrun simctl install booted ./build/Build/Products/Debug-iphonesimulator/screentime.app
    
    echo "🚀 Launching the app..."
    xcrun simctl launch booted world.screentime
    
    echo "✅ ScreenTime app launched successfully!"
else
    echo "📱 Creating and booting first iPhone 16 simulator..."
    DEVICE_ID_1=$(xcrun simctl create "iPhone 16 - Instance 1" "iPhone 16")
    xcrun simctl boot $DEVICE_ID_1
    
    echo "📱 Creating and booting second iPhone 16 simulator..."
    DEVICE_ID_2=$(xcrun simctl create "iPhone 16 - Instance 2" "iPhone 16")
    xcrun simctl boot $DEVICE_ID_2
    
    echo "🖥️ Opening first simulator window..."
    open -a Simulator --args -CurrentDeviceUDID $DEVICE_ID_1
    
    echo "🖥️ Opening second simulator window..."
    open -a Simulator --args -CurrentDeviceUDID $DEVICE_ID_2
    
    echo "📱 Installing the app on first simulator..."
    xcrun simctl install $DEVICE_ID_1 ./build/Build/Products/Debug-iphonesimulator/screentime.app
    
    echo "📱 Installing the app on second simulator..."
    xcrun simctl install $DEVICE_ID_2 ./build/Build/Products/Debug-iphonesimulator/screentime.app
    
    echo "🚀 Launching app on first simulator..."
    xcrun simctl launch $DEVICE_ID_1 world.screentime
    
    echo "🚀 Launching app on second simulator..."
    xcrun simctl launch $DEVICE_ID_2 world.screentime
    
    echo "✅ Successfully launched 2 separate instances!"
    echo "Device IDs: $DEVICE_ID_1 and $DEVICE_ID_2"
fi