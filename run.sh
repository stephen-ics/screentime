#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e

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