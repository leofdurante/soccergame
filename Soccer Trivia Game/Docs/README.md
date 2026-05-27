# Soccer Trivia - Real-Time Multiplayer Game

A real-time soccer trivia game built with SwiftUI and Firebase.

## Setup Instructions

1. **Firebase Setup:**
   - Create a new Firebase project at https://console.firebase.google.com
   - Add an iOS app to your Firebase project
   - Download `GoogleService-Info.plist` and add it to the project root
   - Enable Anonymous Authentication in Firebase Console (Authentication > Sign-in method)
   - Enable Firestore Database in Firebase Console

2. **Install Dependencies:**
   - Open the project in Xcode
   - The Firebase SDK will be installed via Swift Package Manager

3. **Run the App:**
   - Build and run on iOS 17+ device or simulator

## Project Structure

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
└── SoccerTriviaApp.swift
```

## Guess the Player – Wikidata Players

The "Guess the Player" mode uses a local `players.json` generated from **Wikidata** (no API key required).

- **Generate/update players:** From `Soccer Trivia Game/Resources` run  
  `python3 fetch_players_wikidata.py`  
  (options: `--limit N`, `--out players.json`, `--merge`, `--search "Name"`).
- **Validation:** Run `python3 validate_players.py players.json` to ensure each entry has `name` and a valid `photo` http URL.
- **Attribution:** Images come from Wikimedia Commons; add a Credits page in the app and link to Commons/Wikidata. See `Resources/PLAYERS_SETUP.md` for details.

## Features

- Anonymous authentication
- Create/Join rooms with 4-6 digit codes
- Real-time multiplayer synchronization
- Live leaderboard
- 10-second timer per question
- End game results screen

