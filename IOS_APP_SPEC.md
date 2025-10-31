# CORO iOS App - Design Specification

## 🎯 Vision

A beautiful, native iOS app that lets users compare AI model responses side-by-side. The goal is to make it **easy to see how different models think** about the same question.

---

## 🎨 User Experience Design

### Core Flow
1. User enters a question/prompt
2. Selects which models to compare (or use all)
3. Taps "Compare" button
4. Sees all responses appear simultaneously
5. Can scroll through and compare responses
6. Views performance metrics (speed, tokens)

### Key UX Principles
- **Speed**: Responses should feel instant (parallel backend)
- **Clarity**: Easy to see which model said what
- **Simplicity**: No clutter, focus on the comparison
- **Delight**: Smooth animations, haptic feedback

---

## 📱 Screen Design

### Main Screen: Chat Comparison

```
┌─────────────────────────────────┐
│  CORO                    ⚙️     │  <- Navigation bar
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ What's your question?   │   │  <- Prompt input
│  │                         │   │     (multiline text field)
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  Select Models:                 │
│  ☑ Gemini 2.5 Flash            │  <- Model toggles
│  ☑ Llama 3.3 70B               │     (with provider labels)
│  ☑ Llama 3.1 8B                │
│  ☑ Llama 4 Maverick            │
│  ☐ DeepSeek V2.5 (Premium)     │
│                                 │
│  ┌─────────────────────────┐   │
│  │      Compare Models      │   │  <- Primary action button
│  └─────────────────────────┘   │
│                                 │
│  ───── Recent Responses ─────   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 🤖 4 Models • 1.2s      │   │  <- Response card
│  │ "What is Python?"       │   │     (tappable)
│  │ 2 min ago               │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### Results Screen: Tab-Based Comparison

```
┌─────────────────────────────────┐
│  ← Back                    ⋯   │  <- Navigation (Back + Menu)
├─────────────────────────────────┤
│  "What is Python?"              │  <- Original prompt (sticky)
│  Total: 1.2s                    │
│                                 │
│  ┌───────────────────────────┐ │
│  │ Gemini │ Llama 70B │ ... │ │  <- Tab bar (scrollable)
│  └───────────────────────────┘ │     (Active tab highlighted)
│                                 │
│  ┌─────────────────────────┐   │
│  │                         │   │
│  │  Python is a high-level │   │  <- Response content
│  │  programming language   │   │     (scrollable)
│  │  that emphasizes code   │   │
│  │  readability and        │   │
│  │  simplicity. It's       │   │
│  │  widely used for web    │   │
│  │  development, data      │   │
│  │  science, and more...   │   │
│  │                         │   │
│  │                         │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ 📋 Copy  │  664ms • 8t  │   │  <- Action bar (bottom)
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### Settings Screen

```
┌─────────────────────────────────┐
│  ← Settings                     │
├─────────────────────────────────┤
│                                 │
│  API Configuration              │
│  ┌─────────────────────────┐   │
│  │ Backend URL             │   │
│  │ http://localhost:8000   │   │
│  └─────────────────────────┘   │
│                                 │
│  Default Models                 │
│  ☑ Select all by default       │
│                                 │
│  Appearance                     │
│  • System    ○ Light  ○ Dark   │
│                                 │
│  About                          │
│  Version 1.0.0                  │
│  Open Source • MIT License      │
│                                 │
└─────────────────────────────────┘
```

---

## 🏗️ Technical Architecture

### Tech Stack
- **Language:** Swift 5.9+
- **UI Framework:** SwiftUI
- **Architecture:** MVVM (Model-View-ViewModel)
- **Networking:** URLSession with async/await
- **Storage:** UserDefaults for settings
- **Minimum iOS:** iOS 16.0+

### Project Structure
```
CORO-iOS/
├── CoroApp.swift              # App entry point
├── Models/
│   ├── ChatRequest.swift      # Request models
│   ├── ChatResponse.swift     # Response models
│   └── ModelInfo.swift        # Model metadata
├── ViewModels/
│   ├── ChatViewModel.swift    # Main screen logic
│   └── SettingsViewModel.swift
├── Views/
│   ├── ContentView.swift      # Main screen
│   ├── ResponseCardView.swift # Model response card
│   ├── SettingsView.swift     # Settings screen
│   └── Components/
│       ├── PromptInputView.swift
│       └── ModelSelectorView.swift
├── Services/
│   ├── APIService.swift       # Backend communication
│   └── SettingsService.swift  # Persistent settings
└── Utilities/
    ├── Extensions.swift       # Swift extensions
    └── Constants.swift        # App constants
```

### Data Models

```swift
// Request
struct ChatRequest: Codable {
    let prompt: String
    let models: [String]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case prompt, models, temperature
        case maxTokens = "max_tokens"
    }
}

// Response
struct ChatResponse: Codable {
    let responses: [ModelResponse]
    let totalLatencyMs: Int

    enum CodingKeys: String, CodingKey {
        case responses
        case totalLatencyMs = "total_latency_ms"
    }
}

struct ModelResponse: Codable, Identifiable {
    let id = UUID()
    let model: String
    let response: String
    let tokens: Int?
    let latencyMs: Int
    let error: String?

    enum CodingKeys: String, CodingKey {
        case model, response, tokens, error
        case latencyMs = "latency_ms"
    }
}
```

---

## 🎯 Key Features

### Phase 2 MVP (Essential)
- ✅ Prompt input with multiline support
- ✅ Model selection (toggles for each model)
- ✅ Send request to backend
- ✅ Display responses in cards
- ✅ Show loading states
- ✅ Display latency and token count
- ✅ Error handling with user-friendly messages
- ✅ Settings screen for API endpoint

### Phase 2.5 (Nice to Have)
- Recent prompts history
- Copy response to clipboard
- Share responses
- Dark mode support
- Haptic feedback
- Pull to refresh

### Phase 3 (Future)
- Streaming responses (real-time)
- Save favorite prompts
- Response comparison analytics
- Export conversations
- Custom model configurations
- Temperature/max_tokens controls

---

## 🎨 Visual Design

### Color Palette

**Model Colors** (for visual distinction):
- Gemini: Green (#10B981)
- Llama 70B: Blue (#3B82F6)
- Llama 8B: Purple (#8B5CF6)
- Llama 4 Maverick: Orange (#F59E0B)
- DeepSeek: Cyan (#06B6D4)

**System Colors:**
- Primary: iOS System Blue
- Success: Green
- Error: Red
- Warning: Orange
- Background: Dynamic (light/dark)

### Typography
- Headings: SF Pro Rounded Bold
- Body: SF Pro Regular
- Monospace (for code): SF Mono

### Spacing
- Padding: 16pt default
- Card spacing: 12pt
- Corner radius: 12pt for cards

---

## 🔄 State Management

### View States
```swift
enum ViewState {
    case idle           // Initial state
    case loading        // Sending request
    case success        // Responses received
    case error(String)  // Error occurred
}
```

### Model Selection
- Use `@State` for toggle states
- Default: All free models selected
- Persist selection in UserDefaults

### Response Handling
- Use `@Published` in ViewModel
- Update UI reactively with Combine
- Handle partial successes (some models fail)

---

## 🌐 Networking

### API Service
```swift
class APIService {
    private let baseURL: String

    func sendChatRequest(_ request: ChatRequest) async throws -> ChatResponse {
        // URLSession async/await implementation
    }

    func fetchAvailableModels() async throws -> [ModelInfo] {
        // GET /models
    }

    func checkHealth() async throws -> Bool {
        // GET /health
    }
}
```

### Error Handling
- Network errors (no connection)
- Backend errors (500, 400)
- Timeout errors
- Partial failures (some models fail)

---

## 💾 Data Persistence

### UserDefaults Keys
- `apiEndpoint`: Backend URL
- `selectedModels`: Array of model IDs
- `recentPrompts`: Last 10 prompts
- `temperature`: Default temperature
- `maxTokens`: Default max tokens

---

## 🧪 Testing Strategy

### Unit Tests
- ViewModels logic
- Request/Response parsing
- Error handling
- Model selection logic

### UI Tests
- Prompt input
- Model selection
- Response display
- Navigation flow

### Integration Tests
- API communication
- Error scenarios
- Loading states

---

## 🚀 Development Phases

### Phase 2.0 - MVP (Week 1-2)
1. **Day 1-2:** Project setup, models, API service
2. **Day 3-4:** Main screen UI and ViewModel
3. **Day 5-6:** Response display and error handling
4. **Day 7:** Settings screen and polish
5. **Day 8-10:** Testing and bug fixes

### Phase 2.5 - Polish (Week 3)
- Recent prompts history
- Share functionality
- Haptic feedback
- Dark mode optimization

### Phase 3 - Advanced (Week 4+)
- Streaming responses
- Analytics
- Advanced settings

---

## 🎯 Success Criteria

Phase 2 is complete when:
1. ✅ User can enter a prompt
2. ✅ User can select models to compare
3. ✅ App sends request to backend
4. ✅ Responses display correctly
5. ✅ Loading states work
6. ✅ Errors are handled gracefully
7. ✅ Settings allow endpoint configuration
8. ✅ App works on iPhone and iPad

---

## 🔒 Security Considerations

- API endpoint stored locally (no auth needed for MVP)
- HTTPS enforcement in production
- Input validation before sending
- Error messages don't expose sensitive info

---

## 📊 Performance Goals

- App launch: < 1 second
- Response time: Depends on backend (< 2s)
- Smooth scrolling: 60 FPS
- Memory usage: < 50MB
- Battery efficient (minimal background activity)

---

## 🎨 Accessibility

- VoiceOver support
- Dynamic Type support
- High contrast mode
- Reduce motion support
- Keyboard navigation (iPad)

---

## 📱 Platform Support

- **iPhone:** iOS 16.0+
- **iPad:** iPadOS 16.0+
- **Orientation:** Portrait (primary), Landscape (supported)
- **Size classes:** All iPhone and iPad sizes

---

## Next Steps

1. Create Xcode project
2. Set up project structure
3. Implement data models
4. Build API service
5. Create main UI
6. Implement ViewModels
7. Add error handling
8. Test thoroughly
9. Polish and iterate

Ready to start building! 🚀
