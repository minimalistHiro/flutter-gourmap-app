# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is **GourMap** - a comprehensive Flutter-based gourmet mapping application that integrates multiple Firebase services. The app appears to be a restaurant/store discovery and loyalty platform with social features, point systems, and store management capabilities.

## Architecture

### Core Structure
- **Services Layer** (`lib/services/`): Firebase integrations and core business logic
  - `firebase_auth_service.dart` - Authentication and user management
  - `firestore_service.dart` - Database operations
  - `firebase_storage_service.dart` - File storage operations
  - `auth_wrapper.dart` - Authentication state management

- **Views Layer** (`lib/views/`): UI components organized by feature
  - `entry_views/` - Authentication screens (login, signup, welcome)
  - `account_views/` - User account management and store owner features
  - `menu_views/` - Core app features (stores, rankings, friends)
  - `qr_code_views/` - QR code functionality for point systems

### Firebase Integration
The app uses a comprehensive Firebase stack:
- **Authentication**: User login/signup with email
- **Firestore**: Database for user data, stores, posts, notifications
- **Storage**: Image and file storage
- **Analytics**: User behavior tracking
- **Messaging**: Push notifications
- **Crashlytics**: Error reporting
- **Functions**: Server-side logic

## Development Commands

### Essential Flutter Commands
- `flutter run` - Run the app in development mode
- `flutter run -d chrome` - Run in web browser
- `flutter run -d ios` - Run on iOS simulator
- `flutter run -d android` - Run on Android emulator
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter build web` - Build web version

### Development Workflow
- `flutter pub get` - Install dependencies
- `flutter pub upgrade` - Update dependencies
- `flutter pub outdated` - Check for outdated packages
- `flutter clean` - Clean build cache
- `flutter doctor` - Check development environment

### Testing
- `flutter test` - Run unit and widget tests
- `flutter test --coverage` - Run tests with coverage report

### Code Quality
- `dart fix --dry-run` - Preview code fixes
- `dart fix --apply` - Apply automated fixes
- `dart format .` - Format all Dart files
- `flutter analyze` - Static analysis

## Firebase Setup Requirements

### Configuration Files
- `firebase_options.dart` - Auto-generated Firebase configuration
- `firebase.json` - Firebase project configuration
- `firestore.rules` - Database security rules
- `firebase_storage_rules.txt` - Storage security rules
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

### Firebase Functions
Located in `functions/` directory with TypeScript source in `functions/src/`
- `cd functions && npm run deploy` - Deploy cloud functions
- `cd functions && npm run serve` - Run functions locally

## Key Dependencies

### Firebase Stack
- `firebase_core` - Core Firebase functionality
- `firebase_auth` - Authentication
- `cloud_firestore` - Database
- `firebase_storage` - File storage
- `firebase_analytics` - Analytics
- `firebase_messaging` - Push notifications
- `firebase_crashlytics` - Error reporting
- `cloud_functions` - Callable functions

### Additional Features
- `geolocator` - Location services
- `flutter_map` & `latlong2` - Map functionality
- `image_picker` - Camera/gallery access
- `qr_flutter` - QR code generation
- `url_launcher` - External URL handling
- `http` - Network requests

## Platform Support

The app supports multiple platforms:
- **Android**: Full Firebase integration
- **iOS**: Full Firebase integration  
- **Web**: Limited Firebase features (Auth, Analytics)
- **macOS**: Basic functionality
- **Linux**: Basic functionality
- **Windows**: Basic functionality

## Development Notes

### Cross-Platform Considerations
- Firebase Analytics and Crashlytics are disabled on web platform
- Location services behave differently across platforms
- Platform-specific configurations exist for each supported platform

### Authentication Flow
The app uses `AuthWrapper` to manage authentication state, routing users between:
- Welcome/Login screens (unauthenticated)
- Main content view (authenticated)

### Store Management Features
The app includes comprehensive store owner functionality:
- Store creation and editing
- Menu management
- Coupon creation
- Notification management
- Point system management