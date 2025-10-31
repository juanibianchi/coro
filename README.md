# CORO - Multi-LLM Chat Comparison

**CORO** (meaning "Chorus") is a multi-LLM chat application for comparing responses from different AI models side-by-side.

## 🎯 Overview

Compare responses from 5 different AI models simultaneously:
- **Gemini 2.5 Flash** (Google)
- **Llama 3.3 70B** (Groq)
- **Llama 3.1 8B** (Groq)
- **Llama 4 Maverick 17B MoE** (Groq)
- **DeepSeek V2.5** (DeepSeek)

## 🏗️ Architecture

```
coro/
├── backend/          # FastAPI backend (Phase 1 ✅)
└── ios/             # SwiftUI iOS app (Phase 2 - Coming soon!)
```

## ✅ Phase 1: Backend (COMPLETE)

Production-ready FastAPI backend with:
- ✅ **5 LLM integrations** (4 working, 1 needs funding)
- ✅ **Parallel execution** (responses in < 2 seconds)
- ✅ **48 tests** (100% pass rate)
- ✅ **Production logging** (structured, informative)
- ✅ **Robust error handling** (graceful degradation)
- ✅ **Auto-generated API docs** at `/docs`

### Quick Start - Backend

```bash
# Install dependencies
cd backend
pip install -r requirements.txt

# Configure API keys
cp .env.example .env
# Edit .env and add your API keys

# Run tests
python -m pytest tests/ -v

# Start server
cd ..
python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

**Server runs at:** `http://localhost:8000`
**API Docs:** `http://localhost:8000/docs`

### API Endpoints

- `GET /health` - Health check
- `GET /models` - List available models
- `POST /chat` - Multi-model parallel chat
- `POST /chat/{model_id}` - Single model chat

### Test Results

```bash
======================== 48 passed in 4.45s ========================

✅ API Endpoints: 14/14 tests
✅ Schema Validation: 11/11 tests
✅ Error Handling: 13/13 tests
✅ Parallel Execution: 10/10 tests
```

## 🚀 Deployment

The backend is ready to deploy to:
- **Railway** (recommended)
- **Render**
- Any platform supporting Python/FastAPI

See `backend/Procfile` for deployment configuration.

## 📚 Documentation

- **[Backend README](backend/README.md)** - Detailed backend documentation
- **[Test Report](TEST_REPORT.md)** - Comprehensive test coverage report
- **[Production Ready](PRODUCTION_READY.md)** - Deployment checklist
- **[Fixed Status](FIXED_STATUS.md)** - Model fixes and updates

## 🔑 API Keys

You'll need API keys from:
1. **Google Gemini** - https://aistudio.google.com/
2. **Groq** - https://console.groq.com/
3. **DeepSeek** - https://platform.deepseek.com/ (optional)

All are free or very cheap (~$0.14/1M tokens for DeepSeek).

## 🛠️ Tech Stack

### Backend
- **FastAPI** - Modern Python web framework
- **Pydantic** - Data validation
- **httpx** - Async HTTP client
- **pytest** - Testing framework
- **uvicorn** - ASGI server

### iOS App (Coming Soon!)
- **SwiftUI** - Modern declarative UI
- **Swift 5.9+** - Programming language
- **Async/Await** - Concurrency
- **URLSession** - Networking

## 📊 Performance

- **Parallel Execution:** All models queried simultaneously
- **Response Time:** < 2 seconds for all 4 models
- **Individual Models:** 200ms - 1000ms depending on model
- **Proven:** Verified in automated tests

## 🧪 Development

### Run Tests
```bash
cd backend
python -m pytest tests/ -v
```

### Run with Auto-Reload
```bash
python -m uvicorn backend.main:app --reload
```

### Check Code Coverage
```bash
python -m pytest tests/ --cov=backend --cov-report=html
open htmlcov/index.html
```

## 🔒 Security

- ✅ API keys in environment variables (not hardcoded)
- ✅ Input validation with Pydantic
- ✅ CORS configured for frontend
- ✅ Error messages don't expose internals
- ✅ `.env` file in `.gitignore`

## 📈 Roadmap

- ✅ **Phase 1:** FastAPI Backend (COMPLETE)
- 🚧 **Phase 2:** iOS SwiftUI App (In Progress)
- 📋 **Phase 3:** Streaming responses
- 📋 **Phase 4:** Conversation history
- 📋 **Phase 5:** Analytics & insights

## 🤝 Contributing

This is a personal project, but feedback and suggestions are welcome!

## 📝 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

Built with:
- FastAPI by Sebastián Ramírez
- Groq for fast LLM inference
- Google Gemini API
- DeepSeek for cost-effective inference

---

**Status:** Phase 1 Complete ✅ | Production Ready 🚀 | 48/48 Tests Passing ✅
