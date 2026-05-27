# MVP Implementation Plan: Fanáticos-Style Football Quiz

## Overview
This document outlines the phased MVP implementation for a football quiz app with Local and Online Friends modes, featuring a 3-phase game flow and "Guess the Player" question type.

---

## Phase 1: Shared GameEngine + Local Mode (Weeks 1-2)

### Milestones
- ✅ Shared GameEngine state machine (already implemented)
- ⏳ Add `guess_player` question type
- ⏳ Validation service for guess player matching
- ⏳ Local mode driver in Swift
- ⏳ UI for guess player questions

### Deliverables
- `shared-engine/src/validation.ts` - Guess player normalization & matching
- `Soccer Trivia Game/Services/LocalGameDriver.swift` - Local mode wrapper
- `Soccer Trivia Game/Views/GuessPlayerView.swift` - UI component

---

## Phase 2: Player Data Ingestion (Week 2-3)

### Milestones
- ⏳ API-Football integration script
- ⏳ Player data schema & storage
- ⏳ Question generation from player pool
- ⏳ Local caching strategy

### Deliverables
- `backend/scripts/ingestPlayers.ts` - API-Football fetcher
- `backend/src/db/playerRepository.ts` - Player data access
- `backend/src/questionBank/guessPlayerGenerator.ts` - Question builder

---

## Phase 3: Online Friends Lobby + WebSocket (Weeks 3-4)

### Milestones
- ⏳ Room management with short codes
- ⏳ WebSocket server setup
- ⏳ Lobby state synchronization
- ⏳ Host controls & ready system

### Deliverables
- `backend/src/roomManager.ts` - Already implemented
- `backend/src/socketServer.ts` - Already implemented
- Update for guess player message types

---

## Phase 4: Online Gameplay with Authoritative Server (Weeks 4-5)

### Milestones
- ⏳ Server-authoritative round flow
- ⏳ Timer management (server-side)
- ⏳ Answer validation on server
- ⏳ Phase transitions & eliminations
- ⏳ Guess player submission handling

### Deliverables
- `backend/src/gameOrchestrator.ts` - Round orchestration
- `backend/src/timerService.ts` - Already implemented
- Integration with validation service

---

## Phase 5: Guess Player Integration (Week 5-6)

### Milestones
- ⏳ Guess player question selection
- ⏳ Free-text input UI on client
- ⏳ Server validation on submission
- ⏳ Feedback & scoring

### Deliverables
- Updated `GameView.swift` for guess player
- Backend validation endpoint
- Client-server message protocol

---

## File Structure

```
Soccer Trivia Game/
├── shared-engine/              # Platform-agnostic game logic
│   ├── src/
│   │   ├── types.ts           # Data models (add guess_player)
│   │   ├── engine.ts          # State machine
│   │   ├── validation.ts      # NEW: Guess player matching
│   │   └── config.ts
│   └── tests/
│       └── validation.test.ts # NEW: Validation tests
│
├── backend/                    # Node.js + TypeScript server
│   ├── src/
│   │   ├── questionProvider.ts     # Update for guess_player
│   │   ├── validationService.ts    # NEW: Server validation
│   │   ├── db/
│   │   │   └── playerRepository.ts # NEW: Player data access
│   │   └── questionBank/
│   │       └── guessPlayerGenerator.ts # NEW
│   ├── scripts/
│   │   └── ingestPlayers.ts   # NEW: API-Football ingestion
│   └── tests/
│       └── validation.test.ts
│
└── Soccer Trivia Game/         # Swift iOS app
    ├── Services/
    │   ├── LocalGameDriver.swift   # NEW: Local mode wrapper
    │   └── GuessPlayerValidator.swift # NEW: Client-side helper
    ├── Models/
    │   ├── Question.swift          # Update for guess_player
    │   └── PlayerRecord.swift      # NEW: Player data model
    └── Views/
        ├── GuessPlayerView.swift   # NEW: Guess player UI
        └── GameView.swift          # Update to handle guess_player
```

---

## State Machine (Current + Additions)

### Events Added
- `PHASE1_GUESS_SUBMIT` - Guess player submission in Phase 1
- `PHASE3_GUESS_SUBMIT` - Guess player submission in Phase 3

### Transitions (No Changes)
```
Lobby → Phase1 (Elimination) → Phase2 (Duels) → Phase3 (Final) → Ended
```

---

## Data Models

### GuessPlayerQuestion
```typescript
interface GuessPlayerQuestion extends Question {
  type: "guess_player";
  imageUrl: string;
  canonical: {
    first: string;
    last: string;
  };
  aliases: string[];
  constraints: {
    minChars: number;
    allowSingleToken: boolean;
  };
}
```

### PlayerRecord
```typescript
interface PlayerRecord {
  apiPlayerId: number;
  firstName: string;
  lastName: string;
  displayName?: string;
  imageUrl: string;
  generatedAliases: string[];
  curatedNicknames?: string[];
  createdAt: number;
}
```

---

## Validation Rules (Normalization + Matching)

### Normalization Steps
1. Lowercase
2. Remove diacritics (Mbappé → mbappe)
3. Remove punctuation/hyphens/apostrophes
4. Collapse spaces
5. Trim

### Matching Rules (Priority Order)
1. Exact match vs canonical (normalized)
2. Exact match vs any alias (normalized)
3. Token set contains first AND last (any order)
4. If single token allowed: matches first OR last OR alias
5. Optional: fuzzy match vs aliases (Levenshtein threshold = 2)

### Rejections
- Empty or < minChars
- Partial substrings only (e.g., "ron" for "ronaldo")
- No fuzzy match fallback without alias list

---

## WebSocket Message Protocol

### Client → Server (Additions)
```json
{
  "type": "submit_guess",
  "code": "AB12CD",
  "playerId": "p1",
  "roundId": "round_123",
  "text": "Mbappé"
}
```

### Server → Client (Additions)
```json
{
  "type": "round_start",
  "roundId": "round_123",
  "phase": "phase1",
  "question": {
    "type": "guess_player",
    "imageUrl": "https://...",
    "canonical": { "first": "Kylian", "last": "Mbappé" }
  },
  "endsAt": 1768608000000
}
```

---

## Testing Strategy

### Unit Tests
- Guess player validation (accent, nickname, first/last, typo)
- Phase transitions and elimination logic
- Question selection (prevent repeats)

### Integration Tests
- Full game flow (lobby → phase1 → phase2 → phase3 → end)
- Reconnect handling
- Host migration

---

## Next Steps

1. Implement guess player validation service
2. Add guess_player to QuestionType in shared-engine
3. Create player ingestion script
4. Update backend question provider
5. Add guess player UI in Swift

