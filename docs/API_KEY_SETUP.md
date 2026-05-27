# API Key Setup for Guess the Player Mode

## Overview
The "Guess the Player" mode requires an API key from API-Football (API-SPORTS) to search for players.

## Step 1: Get Your API Key

1. Go to https://www.api-football.com/
2. Sign up for a free account
3. Navigate to your dashboard
4. Copy your API key

## Step 2: Add API Key to Xcode Project

### Option A: Using Info.plist (Recommended)

1. **Locate or Create Info.plist:**
   - In Xcode Project Navigator, look for `Info.plist` in the "Soccer Trivia Game" folder
   - If it doesn't exist:
     - Right-click on "Soccer Trivia Game" folder
     - Select "New File..."
     - Choose "Property List"
     - Name it `Info.plist`
     - Make sure it's added to the target

2. **Add API Key Entry:**
   - Open `Info.plist` in Xcode
   - Right-click in the editor → "Add Row"
   - Key: `APISPORTS_KEY` (type: String)
   - Value: Paste your API key here
   - Press Enter to save

3. **Verify Setup:**
   - The entry should look like:
   ```
   APISPORTS_KEY    String    your_api_key_here
   ```

### Option B: Using Build Settings (Alternative)

1. In Xcode, select your project in the navigator
2. Select the "Soccer Trivia Game" target
3. Go to "Build Settings" tab
4. Click the "+" button → "Add User-Defined Setting"
5. Name: `APISPORTS_KEY`
6. Value: Your API key
7. Update `ApiSportsClient.swift` to read from build settings:
   ```swift
   // In loadAPIKey() method, add:
   if let buildKey = Bundle.main.object(forInfoDictionaryKey: "APISPORTS_KEY") as? String {
       return buildKey.isEmpty ? nil : buildKey
   }
   ```

## Step 3: Security - Don't Commit API Key

**IMPORTANT:** Never commit your real API key to git!

1. **Add to .gitignore:**
   - If using Info.plist, add this line to `.gitignore`:
   ```
   Soccer Trivia Game/Info.plist
   ```

2. **Create Template File (Optional):**
   - Create `Info.plist.example` with placeholder:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>APISPORTS_KEY</key>
       <string>YOUR_API_KEY_HERE</string>
   </dict>
   </plist>
   ```
   - Commit `Info.plist.example` instead of `Info.plist`

## Step 4: Verify Configuration

1. Build and run the app
2. Navigate to "Guess the Player" mode
3. If API key is configured correctly, you should be able to search for players
4. If you see "API key not configured" error, check:
   - Info.plist exists and is in the target
   - Key name is exactly `APISPORTS_KEY`
   - Value is not empty
   - Clean build folder (Product → Clean Build Folder) and rebuild

## Troubleshooting

### Error: "API key not configured"
- Verify Info.plist is added to target membership
- Check key name spelling (case-sensitive)
- Ensure value is not empty

### Error: "Invalid API key"
- Verify your API key is correct
- Check if API key has expired (free tier may have limits)
- Ensure no extra spaces in the key

### Error: "Rate Limited"
- Free tier has rate limits
- Wait a few seconds between searches
- Consider upgrading API plan for higher limits

## Testing Without API Key

For testing purposes, you can set an environment variable:
```bash
export APISPORTS_KEY=your_key_here
```

Then run the app from Xcode. The client will fall back to environment variables if Info.plist is not available.

