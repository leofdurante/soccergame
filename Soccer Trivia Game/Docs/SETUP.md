# Soccer Trivia - Setup Guide

## Prerequisites

- Xcode 15.0 or later
- iOS 17.0+ deployment target
- Firebase account (free tier works)

## Step 1: Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose "App" template
   - Product Name: `SoccerTrivia`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 17.0

## Step 2: Add Firebase to Your Project

### Option A: Using Swift Package Manager (Recommended)

1. In Xcode, go to **File > Add Package Dependencies**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: `10.18.0` or later
4. Add these products:
   - `FirebaseAuth`
   - `FirebaseFirestore`
   - `FirebaseFirestoreSwift`
   - `FirebaseCore`

### Option B: Using CocoaPods

Add to your `Podfile`:
```ruby
pod 'Firebase/Auth'
pod 'Firebase/Firestore'
```

## Step 3: Set Up Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Add project" or select existing project
3. Add an iOS app:
   - Bundle ID: Use your Xcode project's bundle identifier
   - Download `GoogleService-Info.plist`
4. Add `GoogleService-Info.plist` to your Xcode project root (drag and drop)

## Step 4: Enable Firebase Services

### Enable Anonymous Authentication

1. In Firebase Console, go to **Authentication > Sign-in method**
2. Enable **Anonymous** authentication
3. Click "Save"

### Enable Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click "Create database"
3. Choose **Start in test mode** (for development)
4. Select a location (choose closest to your users)

### Firestore Security Rules (for development)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /rooms/{roomCode} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Step 5: Add Project Files

Copy all the files from this directory structure into your Xcode project:

```
SoccerTrivia/
├── Models/
│   ├── User.swift
│   ├── Room.swift
│   ├── Question.swift
│   └── GameState.swift
├── Services/
│   ├── AuthService.swift
│   └── FirestoreService.swift
├── ViewModels/
│   ├── AuthViewModel.swift
│   ├── RoomViewModel.swift
│   └── GameViewModel.swift
├── Views/
│   ├── HomeView.swift
│   ├── CreateJoinView.swift
│   ├── LobbyView.swift
│   ├── GameView.swift
│   └── ResultsView.swift
├── Resources/
│   └── questions.json
└── SoccerTriviaApp.swift (replace your App file)
```

**Important:** 
- Make sure `questions.json` is added to your target's "Copy Bundle Resources" in Build Phases
- Replace your default `App.swift` with `SoccerTriviaApp.swift`

## Step 6: Update Info.plist

Add to your `Info.plist` (if not already present):
```xml
<key>UIApplicationSupportsIndirectInputEvents</key>
<true/>
```

## Step 7: Build and Run

1. Select a simulator or device (iOS 17+)
2. Build and run (⌘R)
3. The app should automatically sign in anonymously and show the home screen

## Testing

1. **Create Room**: Tap "Create Room" - you'll see a room code
2. **Join Room**: On another device/simulator, enter the room code
3. **Start Game**: Host taps "Start Game"
4. **Play**: Answer questions within 10 seconds
5. **Results**: After all questions, see the winner

## Troubleshooting

### "Room not found" error
- Check that Firestore is enabled
- Verify security rules allow read/write for authenticated users
- Check that room code is entered correctly

### Authentication fails
- Verify Anonymous auth is enabled in Firebase Console
- Check that `GoogleService-Info.plist` is in the project root
- Ensure bundle ID matches Firebase project

### Questions not loading
- Verify `questions.json` is in "Copy Bundle Resources"
- Check JSON format is valid
- App will fall back to default questions if JSON fails

### Real-time sync not working
- Check Firestore listener permissions
- Verify network connectivity
- Check Firebase Console for errors

## Next Steps

- Add more questions to `questions.json`
- Customize UI colors and styling
- Add sound effects
- Implement player avatars
- Add categories for questions
- Implement power-ups or special rounds

