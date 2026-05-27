# Asset Setup Guide

## Overview
This guide explains how to set up the app icon using `logo.png` and ensure `main image.jpg` is properly loaded.

---

## ✅ Asset Files Location

Your assets are located at:
```
Soccer Trivia Game/images/
  - logo.png
  - main image.jpg
```

---

## 📱 App Icon Setup (logo.png)

### Option A: Using Xcode Asset Catalog (Recommended)

1. **Open Xcode** and navigate to:
   - `Soccer Trivia Game.xcodeproj`
   - Open `Assets.xcassets`
   - Find `AppIcon.appiconset`

2. **Prepare logo.png**:
   - Ensure `logo.png` is at least **1024x1024 pixels** for best quality
   - If smaller, you may need to scale it up (but 1024x1024 is ideal)

3. **Add to AppIcon Set**:
   - In the `AppIcon.appiconset` in Xcode:
     - For **iOS Universal (1024x1024)**: Drag `logo.png` to the slot
     - Xcode will automatically generate the other sizes
   
4. **Or manually add sizes** (if auto-generation doesn't work):
   - Drag `logo.png` to each required size slot in the AppIcon set
   - Required sizes:
     - iOS: 1024x1024 (App Store)
     - iPhone: 60x60, 87x87, 120x120, 180x180 (@2x, @3x variants)

### Option B: Generate Sizes Programmatically (Alternative)

If you prefer, you can use a script to generate all required sizes:

```bash
# In terminal, navigate to project root
cd "/Users/leonardodurante/Documents/Soccer Trivia Game"

# Use sips (built into macOS) to generate sizes
# Note: You'll need to manually place these in Assets.xcassets
sips -z 1024 1024 "Soccer Trivia Game/images/logo.png" --out "Soccer Trivia Game/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
sips -z 180 180 "Soccer Trivia Game/images/logo.png" --out "Soccer Trivia Game/Assets.xcassets/AppIcon.appiconset/AppIcon-180.png"
sips -z 120 120 "Soccer Trivia Game/images/logo.png" --out "Soccer Trivia Game/Assets.xcassets/AppIcon.appiconset/AppIcon-120.png"
sips -z 87 87 "Soccer Trivia Game/images/logo.png" --out "Soccer Trivia Game/Assets.xcassets/AppIcon.appiconset/AppIcon-87.png"
sips -z 60 60 "Soccer Trivia Game/images/logo.png" --out "Soccer Trivia Game/Assets.xcassets/AppIcon.appiconset/AppIcon-60.png"
```

Then update `AppIcon.appiconset/Contents.json` to reference these files.

---

## 🖼️ Background Image Setup (main image.jpg)

The `main image.jpg` is loaded from the `images/` folder in the app bundle.

### Verify in Xcode

1. **Ensure images folder is included in target**:
   - Select `images/` folder in Xcode project navigator
   - In File Inspector (right panel), check **"Target Membership"**
   - Ensure `Soccer Trivia Game` is checked ✅

2. **Verify build phase**:
   - Go to Project Settings → Build Phases → Copy Bundle Resources
   - Verify `main image.jpg` and `logo.png` are listed
   - If not, click "+" and add them

### Code Reference

The code loads images like this:

```swift
Bundle.main.path(forResource: "main image", ofType: "jpg", inDirectory: "images")
Bundle.main.path(forResource: "logo", ofType: "png", inDirectory: "images")
```

**Important**: 
- The resource name is `"main image"` (with space)
- The file type is `"jpg"`
- The directory is `"images"`

If you rename the file, update the code accordingly.

---

## 🎨 Alternative: Move to Asset Catalog (Optional)

If you prefer to use Asset Catalog for images:

1. **In Xcode**:
   - Right-click `Assets.xcassets`
   - Select "New Image Set"
   - Name it `MainImage`
   - Drag `main image.jpg` to the 1x slot
   - Do the same for `logo.png` → `AppLogo`

2. **Update code** to use Asset Catalog:

```swift
// Instead of:
Bundle.main.path(forResource: "main image", ofType: "jpg", inDirectory: "images")

// Use:
Image("MainImage")
  .resizable()
  .scaledToFill()
```

---

## ✅ Verification Checklist

- [ ] `logo.png` is added to `AppIcon.appiconset` in Xcode
- [ ] `images/` folder is included in Target Membership
- [ ] `main image.jpg` and `logo.png` are in "Copy Bundle Resources"
- [ ] App icon appears correctly in Xcode
- [ ] Background image loads when running the app
- [ ] Logo displays on Home screen

---

## 🐛 Troubleshooting

### Images not loading?

1. **Check file names** (case-sensitive):
   - Ensure exact match: `"main image"` (with space)
   - File extension: `.jpg` (not `.jpeg`)

2. **Check Target Membership**:
   - Select file in Xcode
   - File Inspector → Target Membership → Check your app target

3. **Clean Build Folder**:
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Rebuild

4. **Check Bundle Resources**:
   - Build Phases → Copy Bundle Resources
   - Ensure files are listed

### App Icon not showing?

1. **Check AppIcon set**:
   - Open `Assets.xcassets` → `AppIcon`
   - Ensure at least the 1024x1024 slot is filled

2. **Verify in project settings**:
   - Project → Target → General → App Icons and Launch Screen
   - App Icons Source should be `AppIcon`

3. **Delete derived data**:
   - Xcode → Preferences → Locations → Derived Data
   - Delete folder, rebuild

---

## 📝 Notes

- The code uses `Bundle.main.path()` which looks for files in the app bundle
- Images are loaded at runtime, not at compile time
- For production, consider optimizing image sizes (JPEG compression, PNG optimization)

