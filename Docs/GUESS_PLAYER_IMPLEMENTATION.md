# Guess Player Implementation Summary

## Overview
This document summarizes the implementation of the "Guess the Player" question type with flexible validation and player data ingestion from API-Football.

---

## ✅ Completed Components

### 1. Type System (`shared-engine/src/types.ts`)
- Added `"guess_player"` to `QuestionType`
- Created `GuessPlayerQuestion` interface with:
  - `imageUrl`: Player photo URL
  - `canonical`: First/last name structure
  - `aliases`: Nicknames and variations
  - `constraints`: Validation rules (minChars, allowSingleToken)
- Updated `Phase1RoundState` and `Phase3RoundState` to support `guessText` field
- Added `PHASE1_GUESS_SUBMIT` and `PHASE3_GUESS_SUBMIT` events

### 2. Validation Service (`shared-engine/src/validation.ts`)
- **Normalization**: Lowercase, remove diacritics, punctuation, collapse spaces
- **Matching Rules** (priority order):
  1. Exact match vs canonical (normalized)
  2. Exact match vs any alias (normalized)
  3. Token set contains first AND last (any order)
  4. Single token match (first OR last OR alias) if allowed
  5. Fuzzy match vs aliases (Levenshtein threshold = 2)
- **Rejections**: Empty, < minChars, partial substrings only

### 3. Unit Tests (`shared-engine/tests/validation.test.ts`)
- Tests for normalization (accent, case, punctuation)
- Tests for exact matching (canonical, alias, reverse order)
- Tests for token matching (first/last, single token)
- Tests for fuzzy matching (within/beyond threshold)
- Tests for rejection cases (empty, too short, partial substring)

### 4. Player Ingestion Script (`backend/scripts/ingestPlayers.ts`)
- Fetches players from API-Football by league/season
- Converts API response to `PlayerRecord`:
  - `apiPlayerId`, `firstName`, `lastName`, `displayName`
  - `imageUrl` (from API media pattern)
  - `generatedAliases` (auto-generated from name)
  - `curatedNicknames` (manual overlay)
- Saves to local JSON file (`data/players.json`)
- Handles updates vs new players

### 5. Backend Validation Service (`backend/src/validationService.ts`)
- Wrapper for shared validation module
- `GuessPlayerValidationService` implements `ValidationService`
- Validates guess text against question constraints

### 6. Backend Question Provider (`backend/src/questionProvider.ts`)
- Updated to support `guess_player` type
- `getGuessPlayerQuestion()` method (placeholder, needs player DB integration)

---

## 📋 Next Steps (Not Yet Implemented)

### Phase 1: GameEngine Integration
- [ ] Update `GameEngine.handlePhase1Submit()` to handle `PHASE1_GUESS_SUBMIT`
- [ ] Update `GameEngine.handlePhase3Submit()` to handle `PHASE3_GUESS_SUBMIT`
- [ ] Integrate validation service into engine
- [ ] Update answer storage to include `guessText` field

### Phase 2: Player Data Integration
- [ ] Connect `ingestPlayers.ts` to actual player DB (Firestore/SQLite)
- [ ] Implement `PlayerRepository` for player data access
- [ ] Generate guess player questions from player pool
- [ ] Cache player photos locally or use CDN

### Phase 3: Backend WebSocket Messages
- [ ] Add `submit_guess` message handler in `socketServer.ts`
- [ ] Validate guess on server before updating game state
- [ ] Send validation result to client (correct/incorrect feedback)

### Phase 4: Swift Client Integration
- [ ] Add `guess_player` to Swift `Question.QuestionType` enum
- [ ] Create `GuessPlayerView.swift` UI component:
  - Image display
  - Text input field
  - Submit button
  - Validation feedback
- [ ] Integrate into `GameView.swift` for phase 1 and phase 3
- [ ] Add `GuessPlayerValidator.swift` helper (optional, can rely on server)

---

## 🔧 Usage Examples

### Player Ingestion
```bash
# Set API key
export API_KEY=your_api_key

# Fetch EPL players for 2025 season
export API_LEAGUE=39
export API_SEASON=2025
npm run ingest:players

# Or use custom base URL
export API_BASE=https://v3.football.api-sports.io
npm run ingest:players
```

### Validation (TypeScript)
```typescript
import { validateGuessPlayer } from "../../shared-engine/src/validation.js";

const question = {
  canonical: { first: "Kylian", last: "Mbappé" },
  aliases: ["Mbappé", "KM7", "Mbappe"],
  constraints: { minChars: 3, allowSingleToken: true }
};

const result = validateGuessPlayer("mbappe", question);
if (result.isValid) {
  console.log(`Match type: ${result.matchType}`); // "exact_alias"
}
```

### Question Generation (Backend)
```typescript
// Load player from DB
const player = await playerRepository.getById(apiPlayerId);

// Generate question
const question: GuessPlayerQuestion = {
  id: `guess_${player.apiPlayerId}`,
  type: "guess_player",
  text: "Guess the player",
  options: [],
  correctIndex: -1,
  difficulty: 3,
  imageUrl: player.imageUrl,
  canonical: {
    first: player.firstName,
    last: player.lastName
  },
  aliases: [...player.generatedAliases, ...(player.curatedNicknames || [])],
  constraints: {
    minChars: 3,
    allowSingleToken: true
  }
};
```

---

## 📊 Data Flow

### Local Mode
```
User Input → LocalGameDriver → GameEngine (validate locally)
```

### Online Friends Mode
```
User Input → WebSocket → Server (validate on server) → GameEngine → Broadcast
```

### Player Ingestion
```
API-Football → ingestPlayers.ts → PlayerRecord → Local DB → Question Generation
```

---

## 🧪 Testing Strategy

### Unit Tests (Completed)
- ✅ Validation normalization
- ✅ Exact matching (canonical, alias)
- ✅ Token matching (first/last, single)
- ✅ Fuzzy matching (threshold)
- ✅ Rejection cases

### Integration Tests (Todo)
- [ ] Full game flow with guess_player questions
- [ ] Server validation vs client validation consistency
- [ ] Player ingestion → question generation pipeline
- [ ] Reconnect handling with guess_player state

---

## 📝 Notes

### Validation Edge Cases Handled
- Accents: "Mbappé" vs "mbappe" → match
- Case: "KYLIAN MBAPPE" vs "kylian mbappe" → match
- Punctuation: "O'Brien" vs "obrien" → match
- Order: "Kylian Mbappé" vs "Mbappé Kylian" → match
- Single token: "Mbappé" → match (if allowed)
- Fuzzy: "mbapp" vs "mbappe" → match (within threshold)

### Validation Rejections
- Empty string → reject
- < minChars → reject
- Partial substring only (e.g., "ron" for "ronaldo") → reject
- Beyond fuzzy threshold → reject

### Player Data Schema
```typescript
{
  apiPlayerId: number;
  firstName: string;
  lastName: string;
  displayName?: string;
  imageUrl: string;
  generatedAliases: string[];  // Auto-generated
  curatedNicknames?: string[]; // Manual overlay
  createdAt: number;
}
```

---

## 🚀 Deployment Checklist

Before deploying guess_player feature:

1. ✅ Types and validation service implemented
2. ✅ Unit tests passing
3. ⏳ GameEngine integration completed
4. ⏳ Player DB populated (run ingestion script)
5. ⏳ Backend WebSocket handlers updated
6. ⏳ Swift client UI implemented
7. ⏳ Integration tests passing
8. ⏳ Player photos cached or CDN configured

