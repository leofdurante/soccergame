# Soccer Trivia - Architecture Overview

## Architecture Pattern: MVVM

The app follows the **Model-View-ViewModel (MVVM)** architecture pattern, which separates concerns and makes the codebase maintainable and testable.

## Project Structure

```
SoccerTrivia/
├── Models/              # Data models
├── Services/            # Business logic & Firebase integration
├── ViewModels/          # View state management
├── Views/               # SwiftUI views
└── Resources/           # Static assets (JSON, etc.)
```

## Components

### Models

**User.swift**
- Represents a player in the game
- Contains: `id`, `name`, `score`
- Codable for Firestore serialization

**Room.swift**
- Represents a game room
- Contains: `roomCode`, `state`, `hostId`, `players`, `currentQuestionIndex`, `answers`
- Uses `@DocumentID` for Firestore document ID mapping
- Helper properties: `host`, `leaderboard`, `winner`

**Question.swift**
- Represents a trivia question
- Contains: `id`, `text`, `options`, `correctAnswer`, `category`

**GameState.swift**
- Enum for room state: `lobby`, `inGame`, `results`

### Services

**AuthService.swift**
- Handles Firebase Authentication
- Manages anonymous sign-in
- Generates random usernames
- Publishes `currentUser` and `isAuthenticated` state

**FirestoreService.swift**
- Handles all Firestore database operations
- Functions:
  - `createRoom()` - Creates a new game room
  - `joinRoom()` - Adds a player to an existing room
  - `observeRoom()` - Real-time room updates via listeners
  - `updateRoomState()` - Changes game state
  - `updatePlayerScore()` - Updates individual player scores
  - `submitAnswer()` - Records player answers
  - `updateQuestionIndex()` - Advances to next question

### ViewModels

**AuthViewModel.swift**
- Manages authentication UI state
- Wraps `AuthService` for view consumption
- Handles loading and error states

**RoomViewModel.swift**
- Manages room creation/joining
- Observes room changes in real-time
- Handles host actions (start game)
- Publishes: `room`, `isLoading`, `errorMessage`, `isHost`

**GameViewModel.swift**
- Manages game logic and state
- Loads questions from JSON
- Handles question timer (10 seconds)
- Manages answer selection and locking
- Calculates and updates scores
- Advances questions (host only)

### Views

**HomeView.swift**
- Entry point
- Handles authentication
- Shows loading state
- Navigates to `CreateJoinView` when authenticated

**CreateJoinView.swift**
- Create or join room interface
- Room code input
- Error handling
- Navigates to `LobbyView` when room is ready

**LobbyView.swift**
- Displays room code
- Shows player list
- Host sees "Start Game" button
- Shows countdown when game starts
- Navigates to `GameView`

**GameView.swift**
- Main game screen
- Displays question and timer
- Answer selection buttons
- Live leaderboard
- Host sees "Next Question" button
- Navigates to `ResultsView` when game ends

**ResultsView.swift**
- Final scores display
- Winner announcement
- Full leaderboard
- "Back to Home" button

## Data Flow

### Room Creation Flow

1. User taps "Create Room"
2. `RoomViewModel.createRoom()` called
3. `FirestoreService.createRoom()` generates room code and creates Firestore document
4. `RoomViewModel` starts observing room changes
5. Room document updates trigger UI updates via `@Published` properties

### Real-Time Synchronization

1. `FirestoreService.observeRoom()` sets up a Firestore listener
2. Any changes to the room document trigger the listener
3. Room data is decoded and published via `RoomViewModel.room`
4. All connected clients receive updates simultaneously
5. UI automatically updates via SwiftUI's reactive system

### Game Flow

1. Host starts game → `updateRoomState(.inGame)`
2. All clients see countdown → Navigate to `GameView`
3. Questions load from JSON → `GameViewModel.loadQuestions()`
4. Timer starts → 10-second countdown per question
5. Players select answers → Stored in Firestore `answers` map
6. Timer ends → Answers locked
7. Host taps "Next Question" → Scores calculated → Next question index updated
8. Process repeats until all questions answered
9. Final question → State changes to `.results`
10. All clients navigate to `ResultsView`

## Firebase Structure

```
rooms/
  {roomCode}/
    roomCode: "1234"
    state: "lobby" | "inGame" | "results"
    hostId: "user123"
    players: [
      { id: "user123", name: "Player 214", score: 0 },
      { id: "user456", name: "Player 567", score: 10 }
    ]
    currentQuestionIndex: 2
    answers: {
      "user123": 1,
      "user456": 0
    }
    createdAt: Timestamp
```

## Key Design Decisions

1. **Anonymous Auth**: Simple, no user management needed
2. **Firestore over Realtime DB**: Better querying, easier to work with Swift
3. **Room Code System**: Simple 4-6 digit codes for easy sharing
4. **Host-Controlled Flow**: Host advances questions to ensure synchronization
5. **Real-Time Listeners**: All clients stay in sync automatically
6. **Score Calculation**: Happens after each question, not during
7. **Timer-Based Locking**: Answers locked when timer expires

## Future Enhancements

- Automatic question advancement (when all players answer)
- Time-based scoring (faster answers = more points)
- Question categories
- Power-ups or special rounds
- Player avatars
- Sound effects and animations
- Push notifications for game invites
- Room persistence (rejoin after app close)
- Spectator mode

