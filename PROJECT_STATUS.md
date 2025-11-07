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
❌ Web search requires `TAVILY_API_KEY`; lacks caching, per-prompt toggles, and intent gating (global enable only) — this is now the highest-priority follow-up

---

## 🎯 Feature Roadmap

### Phase 1: Core Functionality Improvements

#### 1. Conversation History 📝
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
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
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
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
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
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
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
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

### Phase 1B: Guidance & Context Enhancements

#### Conversation Guidance & Web Context 🤝
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** In Progress
**Priority:** High
**Estimated Effort:** Medium

**Requirements:**
- [x] Backend: Extend `/chat` schema with `conversation_guide` + `search_context` and merge into model-specific system prompts.
- [x] Backend: Provide `/search` proxy (Tavily) with graceful fallback when credentials missing.
- [x] iOS: Persist conversation guide + default search toggle, injecting context for new runs and follow-ups (cloud + on-device).
- [x] iOS: Surface guidance/search context in UI (home chips, results view) and expose settings controls.
- [ ] Backend: Unit tests for `_compose_system_prompt` and search provider errors.
- [ ] iOS: Add automated coverage for prompt builder + context presentation.
- [ ] UX: Consider per-prompt search toggle and “view all sources” affordance in results.

**Notes:**
- Requires `TAVILY_API_KEY` (and optional `TAVILY_ENDPOINT`) to enable web search.
- Default search toggle currently global; evaluate light caching to avoid duplicate queries.
- Intent-driven search (see Phase 1C) will eventually replace the always-on toggle.

---

### Phase 1C: November Spec Alignment

#### 1. Code Execution ⚙️
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Run Python snippets safely inside Docker and stream stdout/stderr/exit status back to the app.

**Tasks:**
- [ ] Backend: Scaffold a `/execute` API that spins up a short-lived Docker container with resource/time limits.
- [ ] Backend: Capture stdout, stderr, and exit code; enforce cancellation for long-running jobs.
- [ ] Backend: Sanitize inputs and guard against filesystem/network access beyond the container sandbox.
- [ ] iOS: Add UI affordance (Workspace view) to submit code, display logs, and surface errors clearly.
- [ ] Monitoring: Emit audit logs + metrics for execution timeouts/failures.

#### 2. Intent-Driven Web Search 🔍
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Priority:** Highest (user-blocking)  
**Goal:** Only hit external search when the user prompt explicitly requires it via a lightweight classifier.

**Tasks:**
- [ ] Backend: Add `/search/intent` classifier or inline model that returns `should_search` + normalized query.
- [ ] Backend: Trigger Tavily search only when classifier returns `true`, attach snippets to model prompts.
- [ ] iOS: Remove always-on search toggle; expose optional UI switch but keep intent as gatekeeper.
- [ ] iOS: Communicate when external data was fetched (e.g., inline badge/timestamp).
- [ ] Testing: Add unit/integration tests covering intent true/false, fallback when classifier or search fails.

#### 3. Model Description Tags 🏷️
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Surface one-liner guidance per model to help users choose the right set.

**Tasks:**
- [ ] Backend/config: Extend model metadata with `tagline` + `recommended_use`.
- [ ] iOS: Show the taglines inside `ModelSelectorView` without cluttering layout.

#### 4. Additional Models 🧠
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Integrate extra free/local models to increase coverage.

**Tasks:**
- [ ] Evaluate candidate open models (e.g., Mistral-small, Phi-3-mini) for latency/cost.
- [ ] Backend: Wire provider clients and expose via `/models`.
- [ ] iOS: Ensure selection grid + response handling supports the larger set (ordering, colors, copy).

#### 5. Quick Diff ✂️
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Highlight deltas between model responses to spotlight unique insights.

**Tasks:**
- [ ] Backend or client diffing strategy (token diff, sentence-level).
- [ ] iOS: Visual treatment (chips/highlights) that remains readable.
- [ ] Accessibility: Ensure VoiceOver describes differences meaningfully.

#### 6. Workspace View 💻
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Provide a coding-focused layout that ties prompts, code, execution, and output together.

**Tasks:**
- [ ] iOS: New Workspace screen with prompt editor, code editor, run button, console output.
- [ ] State management: Sync Workspace with conversation + code execution API.
- [ ] UX: Support iterative refine/run loop with history of executions.

#### 7. Speech-to-Text 🎙️
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Let users dictate prompts (especially for coding use cases).

**Tasks:**
- [ ] Investigate Apple Speech / Whisper / on-device APIs for acceptable accuracy + privacy.
- [ ] iOS: Add microphone control, permission flow, and transcription preview.
- [ ] Error handling + fallback to keyboard input.

#### 8. Fusion Model (Meta-Response) 🧬
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
**Status:** Not Started  
**Goal:** Produce a synthesized “best of” answer after individual models respond.

**Tasks:**
- [ ] Backend: Add fusion pipeline that ingests original prompt + per-model answers and returns a merged response.
- [ ] Model choice: Evaluate using best available cloud model or fine-tuned local option.
- [ ] iOS: UI to display the fused answer alongside individual perspectives; allow opt-in/out.
- [ ] Testing: Validate that fusion respects citations and handles conflicting info gracefully.

---

### Phase 2: New Platforms

#### 5. Web Interface 🌐
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
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
*Branching:* Implement this feature on its own branch and merge only after we confirm it works and we like it.
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

### Session: 2025-11-05 (Web Context & Guide)
**Working on:** Conversation guide + web search integration

**Completed:**
- ✅ Extended backend chat schema to accept `conversation_guide` and `search_context`, composing unified system prompts for Gemini, Groq, DeepSeek, and the in-app MLX model.
- ✅ Wired the new `/search` proxy through iOS so initial runs and follow-ups fetch Tavily results (when enabled) and inject them for every model, including local inference.
- ✅ Surfaced guidance/search context in the app (home chips, results context card) and added Settings controls to edit the guide and toggle default web search.
- ✅ Synced search defaults between Settings and ChatViewModel to prevent drift and ensured conversation guide persists via UserDefaults/Keychain.

**Notes:**
- Document Tavily setup (`TAVILY_API_KEY` + optional endpoint) alongside other env vars.
- Results screen currently shows top three sources; consider expanding or adding a “view all sources” affordance later.

**TODO:**
- [ ] Add backend unit tests for `_compose_system_prompt` and the search proxy fallback behaviour.
- [ ] Gracefully surface provider errors in-app when search credentials are missing or calls fail (banner/alert).
- [ ] Evaluate lightweight caching/deduping for repeated search queries.
- [ ] Outline deferred code execution feature plan (separate branch).

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
- ✅ Improved error UX: consistent backend error codes, richer banners in-app with quick actions, and live “thinking” states for each model

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
- Cerebras integration landed: backend now calls their Chat Completions API (requires `CEREBRAS_API_KEY` + `CEREBRAS_API_URL`), we surface Llama 3.1 8B / 3.3 70B / GPT‑OSS 120B / Qwen 3 32B in `/models`, and rate-limit headers are logged for observability.

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

### Rate Limiting & Redis Notes
- Redis is optional in local development. Without `REDIS_URL`, the rate limiter falls back to an in-memory bucket that resets on app restart.
- To match production behavior, run `docker run --name coro-redis -p 6379:6379 redis/redis-stack:latest` and set `REDIS_URL=redis://localhost:6379` in your environment before launching the backend.
- Premium session tokens from Sign in with Apple are stored in Redis with a 24-hour TTL; in the fallback mode they live in memory only, so restarting the server clears premium access.

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
- Web search proxy: `backend/services/search_service.py`, `backend/routers/search.py`
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
TAVILY_API_KEY=<optional>
TAVILY_ENDPOINT=https://api.tavily.com/search (default)
```

### Future Considerations:
- Database URL (when conversation history is added)
- Redis URL (for caching/rate limiting)
- Monitoring/logging service (Sentry, LogRocket, etc.)

---

**End of Document**
