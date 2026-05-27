# Quick Start Guide

## What You Need to Connect

### 1. Create Xcode Project (REQUIRED)

You currently have source files, but you need an **Xcode project** to build an iOS app.

**Steps:**
1. Open Xcode
2. File → New → Project
3. Choose **iOS** → **App**
4. Fill in:
   - Product Name: `SoccerTrivia`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **iOS 17.0**
5. Save it in `/Users/leonardodurante/Documents/trivia/` (or wherever you prefer)

### 2. Add Your Source Files to Xcode

1. In Xcode, right-click your project folder
2. Select **Add Files to "SoccerTrivia"...**
3. Select all these folders/files:
   - `Models/` folder
   - `Services/` folder
   - `ViewModels/` folder
   - `Views/` folder
   - `SoccerTriviaApp.swift` (replace the default App file)
   - `Resources/questions.json`

**Important:** Make sure `questions.json` is added to "Copy Bundle Resources" in Build Phases.

### 3. Add Firebase SDK (REQUIRED)

**In Xcode:**
1. Click your project in the navigator
2. Select your app target
3. Go to **Package Dependencies** tab
4. Click **+** button
5. Enter: `https://github.com/firebase/firebase-ios-sdk`
6. Click **Add Package**
7. Select these products:
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseFirestoreSwift
   - ✅ FirebaseCore
8. Click **Add Package**

### 4. Set Up Firebase Project (REQUIRED)

1. Go to https://console.firebase.google.com
2. Create a new project (or use existing)
3. Click **Add app** → Choose **iOS**
4. Enter your **Bundle Identifier** (from Xcode project settings)
5. Download `GoogleService-Info.plist`
6. **Drag and drop** `GoogleService-Info.plist` into your Xcode project root
   - ✅ Check "Copy items if needed"
   - ✅ Add to target: SoccerTrivia

### 5. Enable Firebase Services (REQUIRED)

**In Firebase Console:**

**A. Enable Anonymous Authentication:**
1. Go to **Authentication** → **Sign-in method**
2. Enable **Anonymous**
3. Click **Save**

**B. Enable Firestore:**
1. Go to **Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (for development)
4. Select a location

**C. Set Firestore Rules (for development):**
Go to **Firestore Database** → **Rules** tab, paste:

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

Click **Publish**

### 6. Remove Package.swift (Not Needed)

The `Package.swift` file is for Swift packages, not iOS apps. You can delete it - Xcode will manage dependencies instead.

## Checklist

- [ ] Xcode project created
- [ ] All source files added to Xcode project
- [ ] Firebase SDK added via Xcode Package Manager
- [ ] `GoogleService-Info.plist` added to Xcode project
- [ ] Anonymous Authentication enabled in Firebase Console
- [ ] Firestore Database created and rules set
- [ ] Build and run the app!

## Test It

1. Build and run (⌘R)
2. App should auto-sign in anonymously
3. Tap "Create Room"
4. You should see a room code!

## Troubleshooting

**"No such module 'FirebaseAuth'"**
→ Make sure you added Firebase packages in Xcode Package Dependencies

**"GoogleService-Info.plist not found"**
→ Make sure the file is in your Xcode project and added to the target

**"Permission denied" errors**
→ Check Firestore security rules are set correctly

**"Room not found"**
→ Make sure Firestore is enabled and rules allow authenticated users

