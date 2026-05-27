# How to Create Xcode Project and Add Your Files

## Step 1: Create the Xcode Project

**Option A: Create in the same folder (Recommended)**

1. Open **Xcode** (from Applications or Spotlight)
2. You'll see a welcome screen - click **"Create a new Xcode project"**
   - OR if Xcode is already open: **File → New → Project**
3. Choose **iOS** at the top
4. Select **App** template
5. Click **Next**
6. Fill in the details:
   - **Product Name:** `SoccerTrivia`
   - **Team:** (Select your Apple ID if you have one, or leave default)
   - **Organization Identifier:** `com.yourname` (e.g., `com.leonardo`)
   - **Bundle Identifier:** Will auto-fill as `com.yourname.SoccerTrivia`
   - **Interface:** Select **SwiftUI**
   - **Language:** Select **Swift**
   - **Storage:** Select **None** (we'll use Firestore)
   - **Include Tests:** Uncheck (optional)
7. Click **Next**
8. **IMPORTANT:** Navigate to `/Users/leonardodurante/Documents/trivia/`
9. **DO NOT** click "Create" yet!
10. Instead, create a new folder called `SoccerTrivia.xcodeproj` or just save it directly
11. Actually, better: Click **"New Folder"** and name it `SoccerTriviaProject`
12. Select that folder and click **Create**

**Option B: Create in a subfolder (Cleaner)**

1. In Finder, go to `/Users/leonardodurante/Documents/trivia/`
2. Create a new folder called `SoccerTriviaProject`
3. Follow steps 1-7 above
4. When saving, navigate to the `SoccerTriviaProject` folder
5. Click **Create**

## Step 2: Add Your Existing Files to the Project

After the project is created, you'll see Xcode with your new project.

### Add the Source Files:

1. In Xcode's left sidebar (Project Navigator), you'll see a folder structure
2. **Right-click** on the `SoccerTrivia` folder (the blue icon at the top)
3. Select **"Add Files to 'SoccerTrivia'..."**
4. Navigate to `/Users/leonardodurante/Documents/trivia/`
5. Select these folders/files (hold Cmd to select multiple):
   - `Models` folder
   - `Services` folder
   - `ViewModels` folder
   - `Views` folder
   - `SoccerTriviaApp.swift` file
   - `Resources` folder (contains questions.json)
6. **IMPORTANT:** In the dialog that appears:
   - ✅ Check **"Copy items if needed"** (if files are outside project folder)
   - ✅ Check **"Create groups"** (not "Create folder references")
   - ✅ Make sure **"SoccerTrivia"** target is checked
7. Click **Add**

### Replace the Default App File:

1. In Xcode, find `SoccerTriviaApp.swift` (the one Xcode created)
2. **Delete it** (right-click → Delete → Move to Trash)
3. The `SoccerTriviaApp.swift` you just added will be the one used

### Verify questions.json is in Bundle:

1. Click your project (blue icon) in the left sidebar
2. Select the **SoccerTrivia** target
3. Go to **Build Phases** tab
4. Expand **"Copy Bundle Resources"**
5. Make sure `questions.json` is listed there
6. If not, click **+**, find `questions.json`, and add it

## Step 3: Set Minimum iOS Version

1. Click your project (blue icon) in left sidebar
2. Select the **SoccerTrivia** target
3. Go to **General** tab
4. Under **Deployment Info**, set **Minimum Deployments** to **iOS 17.0**

## Step 4: Add Firebase SDK

1. Click your project (blue icon) in left sidebar
2. Select the **SoccerTrivia** project (not target)
3. Go to **Package Dependencies** tab
4. Click the **+** button
5. In the search box, paste: `https://github.com/firebase/firebase-ios-sdk`
6. Click **Add Package**
7. Select version (choose latest, e.g., 10.18.0)
8. Click **Add Package** again
9. Select these products (check the boxes):
   - ✅ FirebaseAuth
   - ✅ FirebaseFirestore
   - ✅ FirebaseFirestoreSwift
   - ✅ FirebaseCore
10. Click **Add Package**

## Step 5: Add GoogleService-Info.plist

**First, get it from Firebase:**

1. Go to https://console.firebase.google.com
2. Create/select a project
3. Click **Add app** → Choose **iOS**
4. Enter your **Bundle Identifier** (from Xcode: com.yourname.SoccerTrivia)
5. Download `GoogleService-Info.plist`

**Then add it to Xcode:**

1. In Finder, find the downloaded `GoogleService-Info.plist`
2. **Drag and drop** it into your Xcode project (into the `SoccerTrivia` folder in the left sidebar)
3. In the dialog:
   - ✅ Check **"Copy items if needed"**
   - ✅ Check **"SoccerTrivia"** target
4. Click **Finish**

## Step 6: Enable Firebase Services

Go to Firebase Console and enable:
- **Authentication → Sign-in method → Enable Anonymous**
- **Firestore Database → Create database → Test mode**

## Step 7: Build and Run!

1. Select a simulator (e.g., iPhone 15) from the device menu at the top
2. Press **⌘R** (or click the Play button)
3. The app should build and run!

## Troubleshooting

**"Cannot find 'FirebaseAuth' in scope"**
→ Make sure you added Firebase packages in Package Dependencies

**"questions.json not found"**
→ Make sure it's in "Copy Bundle Resources" in Build Phases

**Build errors about missing files**
→ Make sure all files are added to the target (check target membership in File Inspector)

