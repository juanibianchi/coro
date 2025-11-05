# CORO - Project Status & Roadmap

**Last Updated:** 2025-11-05

---

## 📊 Current Project State

### Architecture Overview
- **Backend:** FastAPI application with multi-LLM support (Gemini, Groq/Llama, DeepSeek)
- **iOS App:** Native SwiftUI app with tab-based comparison UI
- **Deployment:** Railway (production) at `https://coro-production.up.railway.app`
- **Authentication:** Bearer token authentication (optional)

### What's Working
✅ Backend API with parallel model execution
✅ Error handling with retries and exponential backoff
✅ HTTP/2 connection pooling for performance
✅ CORS configuration for web clients
✅ iOS app with beautiful UI and haptic feedback
✅ Health checks and API key validation
✅ Railway deployment with proper configuration
✅ Bearer token authentication

### Current Limitations
❌ Streaming responses still pending - users wait for full completions
❌ Redis-backed rate limiting optional: without Redis we fall back to in-memory limits (not suitable for multi-instance deploys)
❌ Apple Sign-In verification currently skips signature checks unless `APPLE_CLIENT_ID` is provided
❌ No web interface - iOS only

---

## 🎯 Feature Roadmap

### Phase 1: Core Functionality Improvements

#### 1. Conversation History 📝
**Status:** Not Started
**Priority:** High
**Estimated Effort:** Medium

**Requirements:**
- [ ] Choose storage solution (SQLite for dev, PostgreSQL for production)
- [ ] Design conversation/message schema
- [ ] Backend: Create conversation CRUD endpoints
- [ ] Backend: Associate messages with conversations
- [ ] Backend: Add conversation context to model requests
- [ ] iOS: List of conversations screen
- [ ] iOS: Ability to continue existing conversations
- [ ] iOS: Delete/archive conversations

**Database Schema:**
```sql
conversations:
  - id (uuid, primary key)
  - title (string, auto-generated from first message)
  - created_at (timestamp)
  - updated_at (timestamp)
  - user_id (optional, for future multi-user support)

messages:
  - id (uuid, primary key)
  - conversation_id (uuid, foreign key)
  - role (enum: 'user', 'assistant')
  - content (text)
  - model_id (string, nullable - null for user messages)
  - tokens (integer, nullable)
  - latency_ms (integer, nullable)
  - created_at (timestamp)
```

**Implementation Progress:**
- [ ] Backend: Set up database connection
- [ ] Backend: Create SQLAlchemy models
- [ ] Backend: Implement conversation endpoints
- [ ] Backend: Update chat endpoint to support conversation_id
- [ ] iOS: Add ConversationListView
- [ ] iOS: Update ChatViewModel for conversation context
- [ ] iOS: Add conversation persistence

**Notes:**

---

#### 2. Streaming Responses ⚡
**Status:** Not Started
**Priority:** High
**Estimated Effort:** Medium-High

**Requirements:**
- [ ] Backend: Implement SSE (Server-Sent Events) endpoint
- [ ] Backend: Update each LLM service to support streaming
- [ ] Backend: Handle streaming for multiple models in parallel
- [ ] iOS: Implement SSE client
- [ ] iOS: Update UI to display streaming text
- [ ] iOS: Handle streaming errors gracefully

**Technical Approach:**
- Use FastAPI's `StreamingResponse` with async generators
- Each LLM service yields chunks as they arrive
- Fan out to multiple streams for parallel model comparison
- iOS uses URLSession with delegate for SSE parsing

**Implementation Progress:**
- [ ] Backend: Create `/chat/stream` endpoint
- [ ] Backend: Implement Gemini streaming
- [ ] Backend: Implement Groq streaming
- [ ] Backend: Implement DeepSeek streaming
- [ ] Backend: Parallel streaming coordinator
- [ ] iOS: SSE client implementation
- [ ] iOS: Update ResultsView for streaming
- [ ] iOS: Handle partial responses

**Notes:**

---

#### 3. Model Parameters 🎛️
**Status:** ✅ COMPLETED
**Priority:** Medium
**Estimated Effort:** Low-Medium

**Requirements:**
- [x] Backend: Add parameters to ChatRequest schema
- [x] Backend: Pass parameters to each LLM service
- [x] Backend: Validate parameter ranges
- [x] iOS: UI for temperature, max_tokens, top_p sliders
- [x] iOS: Per-request parameter overrides

**Parameters Supported:**
- `temperature` (0.0 - 2.0, default 0.7) ✅
- `max_tokens` (1 - 32000, default 2000) ✅
- `top_p` (0.0 - 1.0, optional) ✅

**Implementation Progress:**
- [x] Backend: Update schemas with optional parameters
- [x] Backend: Add parameter support to Gemini service
- [x] Backend: Add parameter support to Groq service
- [x] Backend: Add parameter support to DeepSeek service
- [x] iOS: Add ModelParametersSheet view
- [x] iOS: Update ChatViewModel with parameter properties
- [x] iOS: Update ChatRequest model with topP

**Notes:**
- Expanded temperature range to 2.0 (was 1.0)
- Increased max_tokens limit to 32000 (was 4096)
- Added optional top_p nucleus sampling parameter
- Created beautiful iOS UI for parameter configuration
- Parameters persist in ChatViewModel for session

---

#### 4. Better Error UX 🚨
**Status:** Not Started
**Priority:** Medium
**Estimated Effort:** Low

**Requirements:**
- [ ] Backend: Standardize error responses with codes
- [ ] Backend: Add detailed error messages (rate_limit, auth_failed, timeout, etc.)
- [ ] Backend: Log errors with context
- [ ] iOS: Parse error types
- [ ] iOS: Show user-friendly error messages
- [ ] iOS: Add retry button per-model
- [ ] iOS: Handle partial failures gracefully

**Error Types to Handle:**
- `authentication_failed` - Invalid API key
- `rate_limited` - Too many requests
- `timeout` - Request took too long
- `model_overloaded` - Service temporarily unavailable
- `invalid_request` - Bad parameters
- `unknown_error` - Catch-all

**Implementation Progress:**
- [ ] Backend: Create error code enum
- [ ] Backend: Update exception handlers
- [ ] Backend: Add structured error responses
- [ ] iOS: Create ErrorView component
- [ ] iOS: Add retry logic
- [ ] iOS: Display error badges per model

**Notes:**

---

### Phase 1A: Brand & Foundation Refresh
- [x] Update in-app language to speak about perspectives instead of comparisons
- [x] Replace primary CTA with "Ask Multiple AIs" copy
- [x] Implement shared AppTheme color system
- [x] Establish typography hierarchy (hero/title/subtitle/body/caption)
- [x] Add skeleton loading states for idle/loading experiences
- [x] Implement rate limiting service (Redis-backed with in-memory fallback)
- [x] Add BYOK settings screen storing keys securely in Keychain
- [x] Integrate Sign in with Apple and premium session handling
- [ ] Document Redis setup + sample docker compose for dev environments
- [ ] Refresh marketing copy / external docs to match new messaging

---

### Phase 2: New Platforms

#### 5. Web Interface 🌐
**Status:** Not Started
**Priority:** High
**Estimated Effort:** High

**Requirements:**
- [ ] Choose framework (React/Next.js, Vue, or Svelte)
- [ ] Set up project structure
- [ ] Implement authentication flow
- [ ] Build chat interface
- [ ] Build conversation history view
- [ ] Implement streaming support
- [ ] Add settings page
- [ ] Responsive design (mobile + desktop)
- [ ] Deploy to Vercel/Netlify

**Technical Stack (Proposed):**
- Framework: Next.js 14 (App Router)
- Styling: Tailwind CSS
- State: Zustand or React Context
- API Client: fetch with SSE support
- Deployment: Vercel

**Implementation Progress:**
- [ ] Project setup and configuration
- [ ] Authentication UI
- [ ] Chat interface component
- [ ] Model comparison tabs
- [ ] Streaming implementation
- [ ] Conversation history
- [ ] Settings page
- [ ] Production deployment

**Notes:**

---

### Phase 3: Quality of Life

#### 6. Markdown Rendering 📄
**Status:** ✅ COMPLETED
**Priority:** Medium
**Estimated Effort:** Low

**Current State:**
- iOS app ALREADY has markdown support via `MarkdownText.swift` component
- Uses native `AttributedString(markdown:)` API
- Integrated in `MessageBubbleView.swift`

**Implementation Progress:**
- [x] Verify current iOS markdown rendering - CONFIRMED
- [x] Update response display views - ALREADY DONE
- [ ] Add syntax highlighting for code blocks (future enhancement)
- [ ] Test with various markdown samples (should test)

**Notes:**
- Located at `CORO/CORO/Views/Components/MarkdownText.swift`
- Works with inline markdown, preserving whitespace

---

## 🔄 Active Development Log

### Session: 2025-11-05
**Working on:** Chat UX responsiveness & history cleanup

**Completed:**
- ✅ Auto-select the first completed model response so users see answers immediately instead of placeholders
- ✅ Standardized response ordering (request + restore) to keep model tabs stable across runs and history loads
- ✅ Split prompt state so the home input stays blank after a run while results retain the original question
- ✅ Deferred conversation persistence until responses finish and ignored placeholder-only runs to stop duplicate history rows
- ✅ Cleared per-model prompt history when leaving the results screen to avoid accidental carry-over
- ✅ Simplified history timestamps (no seconds) and updated primary CTA copy to “Ask Multiple AIs”
- ✅ Follow-up questions now appear instantly with a “thinking” assistant bubble so users know processing started
- ✅ Results toolbar uses a single hamburger entry with menu actions, and the home screen now exposes response parameters via an inline card instead of a second top-bar button
- ✅ Restored chronological ordering for saved conversations using explicit message indices so history replays match live chat order
- ✅ Results screen lives in-line again with a single back affordance, keeping navigation consistent while eliminating the old “Return to Prompt” action
- ✅ Added in-app education for Apple Sign-In benefits and BYOK via home upsell cards + refreshed Settings copy so users understand premium access and key storage
- ✅ Polished surface styling (capsule handles, card shadows, consistent overlays) to tighten the pro iOS feel across results and home
- ✅ Follow-up menu offers “Ask every model” so side-questions can be broadcast without retyping

**Notes:**
- Follow-up: monitor follow-up reply flow; consider persisting conversation updates instead of insert-only if needed.
- TODO: Add microphone-driven voice prompts (Speech framework integration) so users can dictate instead of typing.
- TODO (separate branch): Implement response streaming end-to-end  
  - Backend  
    - [ ] Add an `/chat/stream` SSE endpoint that multiplexes model chunks and keeps the existing JSON response for non-stream clients  
    - [ ] Update Gemini/Groq/DeepSeek service wrappers to expose async generators (fallback to chunking full responses if native streaming unsupported)  
    - [ ] Rework rate limiter + logging so partial sends are accounted for and cancellation cleans up background tasks  
  - iOS  
    - [ ] Introduce an `AsyncSequence`/`URLSession.bytes(for:)` client with retry/backoff  
    - [ ] Show incremental text with proper diffing (per-model) and a “finalized” state once completion arrives  
    - [ ] Preserve existing non-stream flow behind a feature flag for comparison/tests  
  - QA  
    - [ ] Add timeout / disconnect tests, validate dark-mode skeletons during partial renders, and document fallback behaviour in README

---

### Session: 2025-11-04
**Working on:** Model Parameters Implementation

**Completed:**
- ✅ Fixed Railway deployment (httpx[http2] dependency)
- ✅ Updated iOS app with Railway URL and auth token support
- ✅ Verified iOS app builds successfully
- ✅ Created comprehensive project status document
- ✅ Verified markdown rendering already implemented in iOS
- ✅ **Model Parameters Feature (COMPLETE)**:
  - Backend: Updated schemas (temperature 0-2.0, max_tokens 1-32000, top_p optional)
  - Backend: Updated chat router to pass parameters
  - Backend: Added parameter support to all services (Gemini, Groq, DeepSeek)
  - Backend: Tested parameter validation
  - iOS: Updated ChatRequest model with topP
  - iOS: Added parameter properties to ChatViewModel
  - iOS: Created ModelParametersSheet UI with sliders
  - iOS: Integrated parameters into request flow

**Next Steps:**
1. ~~Model Parameters~~ ✅ COMPLETELY DONE (including UI integration)
2. ~~Add button to show ModelParametersSheet~~ ✅ DONE
3. ~~Test iOS app build~~ ✅ BUILD SUCCEEDED
4. Choose next feature: Better Error UX, Conversation History, or Streaming

**Ready to begin:**
- Conversation History (backend + iOS)
- Streaming Responses (backend + iOS)
- Better Error UX (backend + iOS)
- Web Interface (new project)

**Blockers:** None

---

### Session: 2025-11-04 (Later)
**Working on:** iOS Build Fix

**Completed:**
- ✅ Fixed `ChatViewModel` initialization to instantiate `APIService`/`MLXService` on the main actor, resolving the Swift concurrency build error
- ✅ Verified simulator build succeeds (`xcodebuild -project CORO.xcodeproj -scheme CORO -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData -clonedSourcePackagesDirPath ./Packages CODE_SIGNING_ALLOWED=NO build`)

**Notes:**
- The sandbox blocks writing to the default SwiftPM caches, so keep `TMPDIR`, `DerivedData`, and `Packages` inside the repo when building.
- Fetching Swift packages requires network access.

---

### Session: 2025-11-04 (Even Later)
**Working on:** iOS UI Overhaul & Dark Mode Pass

**Completed:**
- ✅ Introduced `AppTheme` token system for adaptive colors, typography, and gradients
- ✅ Updated all primary SwiftUI screens (home, results, sidebar, settings, parameters, history) to honor dark mode backgrounds and improve contrast
- ✅ Added explicit “Back” control in results view so users can return to prompt/model selection after a run
- ✅ Removed default selection of the heavy on-device MLX model to reduce perceived slowness on phones
- ✅ Cloud model results now appear immediately; on-device MLX responses stream in asynchronously
- ✅ Split chat execution per-model so the fastest responses render first while local/slow models catch up in-place
- ✅ Hardened conversation restoration (no duplicate saves, stable message order, prompt clears when returning home)
- ✅ Verified simulator build still passes after UI refactor (`xcodebuild -project CORO.xcodeproj -scheme CORO -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath ./DerivedData -clonedSourcePackagesDirPath ./Packages CODE_SIGNING_ALLOWED=NO build`)

**Notes:**
- Sheets and menus now use themed backgrounds; avoid reintroducing hard-coded light colors to keep dark mode intact.
- Sidebar close button was removed; swipe or tap outside to dismiss.

---


### Session: 2025-11-04 (Night)
**Working on:** Phase 1A foundation & rebranding tasks

**Completed:**
- ✅ Added configurable rate limiting (Redis + in-memory fallback) and Apple premium session tracking
- ✅ Introduced BYOK Keychain storage and exposed overrides through the chat pipeline
- ✅ Integrated Sign in with Apple flow in iOS with premium session handshake
- ✅ Refreshed settings UI, CTA copy, and new messaging ("Ask Multiple AIs")
- ✅ Updated iOS networking stack to send device/session headers + secure token storage

**Notes:**
- Redis remains optional for local dev; production deploys should supply `REDIS_URL` for consistent limits.
- Sign in verification skips signature checks unless `APPLE_CLIENT_ID` is configured.

**Next Focus:** Continue Phase 1 roadmap (Better error UX, streaming) once foundation tasks are validated.

---

## 📝 Development Guidelines

### When Working on Features:
1. **Always update this document first** - Mark what you're working on
2. **Update progress regularly** - Check off tasks as you complete them
3. **Document decisions** - Add notes about technical choices
4. **Flag blockers** - Note anything preventing progress
5. **Test thoroughly** - Don't mark as done until tested

### Handoff Protocol:
When pausing work or handing off to another agent:
1. Update "Active Development Log" with current status
2. Check off completed tasks
3. Note any WIP (work in progress) items
4. Document any gotchas or important context
5. List clear next steps

### Git Commit Strategy:
- Feature branches: `feature/conversation-history`, `feature/streaming`, etc.
- Commit messages: Follow conventional commits (feat:, fix:, docs:, etc.)
- PR descriptions: Link to relevant sections of this document

---

## 🎓 Learning & Resources

### Documentation References:
- FastAPI Streaming: https://fastapi.tiangolo.com/advanced/custom-response/#streamingresponse
- SQLAlchemy Async: https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html
- Server-Sent Events: https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events
- SwiftUI AsyncStream: https://developer.apple.com/documentation/swift/asyncstream

### Key Files:
- Backend main: `backend/main.py`
- Backend config: `backend/config.py`
- API routes: `backend/routers/chat.py`
- LLM services: `backend/services/*.py`
- iOS app: `CORO/CORO/` (note: separate from `ios/CORO/`)
- iOS API client: `CORO/CORO/Services/APIService.swift`

---

## 🚀 Deployment

### Current Setup:
- **Backend:** Railway (auto-deploys from main branch)
- **iOS:** Manual Xcode build
- **Web:** Not yet deployed

### Environment Variables:
```
GEMINI_API_KEY=<secret>
GROQ_API_KEY=<secret>
DEEPSEEK_API_KEY=<optional>
CORS_ALLOWED_ORIGINS=*
CORS_ALLOW_CREDENTIALS=true
CORO_API_TOKEN=<secret>
```

### Future Considerations:
- Database URL (when conversation history is added)
- Redis URL (for caching/rate limiting)
- Monitoring/logging service (Sentry, LogRocket, etc.)

---

**End of Document**
