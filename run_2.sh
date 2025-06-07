#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

echo "🏗️ Building the project..."
xcodebuild -project screentime.xcodeproj \
           -scheme screentime \
           -destination 'platform=iOS Simulator,name=iPhone 16' \
           -derivedDataPath ./build \
           clean build

echo "📱 Booting first iPhone 16 simulator..."
DEVICE_ID_1=$(xcrun simctl create "iPhone 16 - Instance 1" "iPhone 16")
xcrun simctl boot $DEVICE_ID_1

echo "📱 Booting second iPhone 16 simulator..."
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