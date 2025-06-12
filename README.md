# ScreenTime App

A modern iOS app for managing family screen time and digital wellbeing.

## Architecture

### Authentication
- Family-based authentication system using `FamilyAuthService`
- Single Supabase auth account per family
- Separate profile management for parents and children
- Secure session management and token handling

### Key Components
- `FamilyAuthService` - Handles family authentication and profile management
- `SupabaseDataRepository` - Manages data persistence and real-time updates
- `AppRouter` - Handles navigation and deep linking

### Views
- `ContentView` - Main app entry point with authentication flow
- `ParentDashboardView` - Parent's main interface
- `ChildDashboardView` - Child's main interface
- `AuthenticationView` - Handles sign in/sign up
- `EmailVerificationView` - Manages email verification process

## Features

### Family Management
- Create and manage family accounts
- Add and manage child profiles
- Set screen time limits and schedules
- Monitor app usage and activity

### Parent Features
- Dashboard with family overview
- Screen time management
- App approval system
- Task and reward system
- Activity monitoring

### Child Features
- Personalized dashboard
- Screen time tracking
- Task completion
- Reward redemption
- Activity history

## Development

### Setup
1. Clone the repository
2. Install dependencies
3. Configure Supabase project
4. Set up environment variables

### Building
```bash
xcodebuild -scheme ScreenTime -configuration Debug
```

### Testing
```bash
xcodebuild test -scheme ScreenTime -destination 'platform=iOS Simulator,name=iPhone 14'
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
