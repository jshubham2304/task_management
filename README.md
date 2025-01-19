# Task Manager App

A Flutter-based task management application with offline-first functionality and Firebase synchronization.

## Features

- ✨ Beautiful black and white theme with smooth animations
- 📱 Offline-first functionality using Hive
- 🔄 Real-time synchronization with Firebase
- 🎯 Clean Architecture with BLoC pattern
- ⚡ Optimistic UI updates
- 🔌 Automatic offline/online mode switching
- 🎨 Material Design 3 components

## Architecture

The app follows Clean Architecture principles with the following layers:

1. **Presentation Layer**

   - Widgets
   - Pages
   - BLoC (State Management)

2. **Domain Layer**

   - Entities
   - Repositories (Abstract)
   - Use Cases

3. **Data Layer**
   - Models
   - Repositories (Implementation)
   - Data Sources
   - DTO Objects

## Setup Instructions

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Firebase project

### Firebase Setup

1. Create a new Firebase project in the [Firebase Console](https://console.firebase.google.com/)
2. Enable Cloud Firestore
3. Add a new Android/iOS app and download the configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Place these files in their respective locations:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### Project Setup

1. Clone the repository:

```bash
git clone https://github.com/jshubham2304/task_manager.git
cd task_manager
```

2. Install dependencies:

```bash
flutter pub get
```

3. Generate Hive adapters:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:

```bash
flutter run
```

### Running Tests

Execute unit and widget tests:

```bash
flutter test
```

## Key Components

### Task Management

- Create, update, and delete tasks
- Mark tasks as complete/incomplete
- Offline support with local storage
- Automatic synchronization when online

### UI/UX Features

- Smooth animations for task transitions
- Pull-to-refresh synchronization
- Optimistic updates for instant feedback
- Error handling with user-friendly messages
- Offline mode indicator

### State Management

- BLoC pattern for state management
- Clean separation of concerns
- Reactive programming with Streams
- Error handling and recovery

#### Previews

[S1](./preview/Screenshot_20250119_181731.jpg)
