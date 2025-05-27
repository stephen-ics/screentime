# ScreenTime Manager

A production-ready iOS application that helps parents monitor and manage their children's screen time through a task-based reward system.

## Features

- 👥 Multi-user support (Parent/Child accounts)
- ✅ Task management system with time rewards
- ⏳ Real-time screen time tracking and countdown
- 🔒 App lockout system with parental override
- 📱 App usage tracking and monitoring
- 🔔 Smart notification system
- 🌙 Dark mode support
- ♿️ Full accessibility support
- ☁️ CloudKit sync across devices
- 🔐 Secure authentication with Face ID/Touch ID

## Architecture

The app follows MVVM (Model-View-ViewModel) architecture with the following key components:

### Core Layers
- **Models**: Core data models and business logic
- **Views**: SwiftUI views and UI components
- **ViewModels**: State management and business logic
- **Services**: Core services (Authentication, Notifications, etc.)

### Key Technologies
- SwiftUI for modern UI development
- Combine for reactive programming
- CloudKit for data synchronization
- Core Data for local persistence
- DeviceActivity for app usage tracking
- LocalAuthentication for secure access

## Project Structure

```
screentime/
├── App/
│   ├── screentimeApp.swift
│   └── AppDelegate.swift
├── Models/
│   ├── Task.swift
│   ├── User.swift
│   └── ScreenTimeBalance.swift
├── Views/
│   ├── Parent/
│   ├── Child/
│   └── Shared/
├── ViewModels/
│   ├── TaskViewModel.swift
│   ├── UserViewModel.swift
│   └── ScreenTimeViewModel.swift
├── Services/
│   ├── AuthenticationService.swift
│   ├── NotificationService.swift
│   ├── CloudKitService.swift
│   └── AppTrackingService.swift
├── Utils/
│   ├── Constants.swift
│   └── Extensions/
└── Resources/
    ├── Assets.xcassets
    └── Localizable.strings
```

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Setup

1. Clone the repository
2. Open `screentime.xcodeproj` in Xcode
3. Configure your development team and bundle identifier
4. Build and run

## Security

- All sensitive operations require Face ID/Touch ID authentication
- Data is encrypted at rest using iOS data protection
- Network communications use TLS 1.3
- No sensitive data is logged or stored in plain text

## Testing

The project includes:
- Unit tests for business logic
- UI tests for critical user flows
- Integration tests for service layer

## License

Copyright © 2024 ScreenTime Manager. All rights reserved. # screentime
