# CORO iOS App

Beautiful native iOS app for comparing AI model responses side-by-side.

## 🎨 Design Philosophy

Inspired by Claude's iOS app - clean, polished, and delightful to use.

### Key Features
- **Tab-based comparison** - Swipe between model responses
- **Flexible model selection** - Choose 1, 2, or all models
- **Copy to clipboard** - One tap to copy any response
- **Real-time performance metrics** - See latency and token count
- **Haptic feedback** - Satisfying tactile responses
- **Dark mode support** - Automatic theme adaptation

## 📱 Screenshots

[Coming soon after Xcode project is created]

## 🏗️ Project Setup

### Prerequisites
- macOS 13.0+
- Xcode 15.0+
- iOS 16.0+ deployment target

### Creating the Xcode Project

1. **Open Xcode**
2. **Create New Project**
   - Choose "iOS" → "App"
   - Product Name: `CORO`
   - Team: Your team
   - Organization Identifier: `com.yourname`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Storage: None
   - Include Tests: Yes (optional)

3. **Add Source Files**
   - Delete the default `ContentView.swift` and `CoroApp.swift` if created
   - Drag all files from `ios/CORO/` into your Xcode project
   - Make sure "Copy items if needed" is checked
   - Create Groups (not folder references)

### Project Structure
```
CORO/
├── CoroApp.swift              # App entry point
├── Models/
│   └── ChatModels.swift       # Data models
├── ViewModels/
│   └── ChatViewModel.swift    # Business logic
├── Views/
│   ├── ContentView.swift      # Main screen
│   ├── ResultsView.swift      # Tab-based results
│   ├── SettingsView.swift     # Settings
│   └── Components/
│       └── ModelSelectorView.swift
├── Services/
│   └── APIService.swift       # Backend communication
└── Assets.xcassets/           # Images & colors
```

## 🚀 Running the App

### 1. Configure Backend URL

Default: `http://localhost:8000`

For testing on physical device:
```swift
// In Settings → API Configuration
// Replace with your computer's local IP
http://192.168.1.XXX:8000
```

### 2. Start Backend Server

```bash
cd ../backend
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

### 3. Run the App

- Select iPhone simulator (iPhone 14 Pro recommended)
- Press Cmd+R or click Run
- App should launch and connect to backend

## 🎨 UI Components

### Main Screen
- Multiline prompt input
- Model selection with toggles
- "Compare Models" button
- Loading states

### Results Screen
- Scrollable tab bar for models
- Full-screen response content
- Copy button with confirmation
- Performance metrics (latency, tokens)
- Error states for failed models

### Settings
- Backend URL configuration
- Connection test button
- App version info

## 🔧 Customization

### Colors

Model colors are defined in `ChatViewModel.swift`:

```swift
func getModelColor(_ modelId: String) -> Color {
    switch modelId {
    case "gemini": return .green
    case "llama-70b": return .blue
    case "llama-8b": return .purple
    case "mixtral": return .orange
    case "deepseek": return .cyan
    default: return .gray
    }
}
```

### API Endpoint

Set in `Services/APIService.swift`:

```swift
init() {
    self.baseURL = UserDefaults.standard.string(forKey: "apiEndpoint")
        ?? "http://localhost:8000"
}
```

## 🧪 Testing

### Manual Testing Checklist

**Input Screen:**
- [ ] Can type in prompt field
- [ ] Can select/deselect models
- [ ] "Select All" / "Deselect All" works
- [ ] Button disabled when no input/models
- [ ] Loading state shows during request

**Results Screen:**
- [ ] Tabs appear for each model
- [ ] Can swipe/tap between tabs
- [ ] Responses display correctly
- [ ] Copy button works
- [ ] "Copied!" confirmation shows
- [ ] Error states display properly
- [ ] Back button returns to input

**Settings:**
- [ ] Can edit backend URL
- [ ] Test connection works
- [ ] Settings persist across launches

## 🐛 Troubleshooting

### "Cannot connect to backend"

1. Check backend is running: `curl http://localhost:8000/health`
2. On physical device, use computer's IP address
3. Check firewall isn't blocking port 8000

### "No models available"

1. Backend may be down
2. Check `/models` endpoint: `curl http://localhost:8000/models`
3. App uses fallback models if API fails

### "Responses not showing"

1. Check Xcode console for errors
2. Verify API response format matches models
3. Check network requests in Charles/Proxyman

## 📱 Deployment

### App Store Preparation

1. **Bundle Identifier**: `com.yourname.CORO`
2. **Version**: 1.0.0
3. **Build Number**: 1
4. **Deployment Target**: iOS 16.0
5. **Required Permissions**: None (uses local network)

### TestFlight

1. Archive the app (Product → Archive)
2. Upload to App Store Connect
3. Add to TestFlight
4. Share with testers

## 🎯 Roadmap

### Phase 2.0 (MVP) ✅
- [x] Tab-based comparison
- [x] Model selection
- [x] Copy to clipboard
- [x] Error handling
- [x] Settings screen
- [x] Haptic feedback

### Phase 2.5 (Polish)
- [ ] Recent prompts history
- [ ] Share responses
- [ ] Custom color themes
- [ ] Temperature/max_tokens controls
- [ ] Markdown rendering

### Phase 3 (Advanced)
- [ ] Streaming responses
- [ ] Conversation history
- [ ] Favorites
- [ ] Export to various formats
- [ ] iPad optimization
- [ ] Widgets

## 🤝 Contributing

This is a personal project, but feedback is welcome!

## 📄 License

MIT License - See LICENSE file for details

---

**Built with SwiftUI • iOS 16+ • Swift 5.9+**
