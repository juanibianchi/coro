# CORO - Phase 1 Specification

## Overview

**CORO** (meaning "Chorus") is a multi-LLM chat application for comparing responses from different AI models side-by-side.

**Phase 1 Goal:** Build a production-ready FastAPI backend that integrates 5 LLM APIs and enables multi-model chat comparison.

---

## Technical Requirements

### Technology Stack
- **Python 3.11+**
- **FastAPI** - async web framework
- **Pydantic** - data validation
- **httpx** - async HTTP client
- **uvicorn** - ASGI server
- **python-dotenv** - environment management

### LLM Integrations (5 models)

1. **Google Gemini 1.5 Flash**
   - SDK: `google-generativeai`
   - Free tier: 15 req/min
   - Fast and efficient

2. **Groq - Llama 3.1 70B**
   - SDK: `groq`
   - Model: `llama-3.1-70b-versatile`
   - Free tier: 30 req/min

3. **Groq - Llama 3.1 8B**
   - SDK: `groq` (same as above)
   - Model: `llama-3.1-8b-instant`
   - Faster, smaller variant

4. **Groq - Mixtral 8x7B**
   - SDK: `groq` (same as above)
   - Model: `mixtral-8x7b-32768`
   - Mixture-of-experts architecture

5. **DeepSeek V2.5**
   - No official SDK - use direct HTTP API
   - Endpoint: `https://api.deepseek.com/v1/chat/completions`
   - Nearly free: ~$0.14/1M tokens

---

## Core Functionality

### 1. Multi-Model Parallel Execution
- Send same prompt to multiple models **simultaneously**
- Use `asyncio.gather()` for parallel execution
- Total response time should be ~= slowest model (not sum of all)
- Target: < 6 seconds for all 5 models

### 2. Independent Error Handling
- One model failure should **NOT** break the entire request
- If Gemini fails, Groq models should still return results
- Return errors in response with `error` field populated
- Never return HTTP 500 unless ALL models fail

### 3. Configuration Management
- All API keys via environment variables (`.env` file)
- No hardcoded secrets
- Validate keys on startup
- Clear error messages if keys missing

### 4. Deployment Ready
- Must work on Railway/Render free tier
- Include `Procfile` for deployment
- CORS enabled for future iOS app
- Health check endpoint for monitoring

---

## API Specification

### Endpoints to Implement

#### `GET /health`
Health check for monitoring.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-30T12:00:00Z"
}
```

#### `GET /models`
List all available models with metadata.

**Response:**
```json
{
  "models": [
    {
      "id": "gemini",
      "name": "Gemini 1.5 Flash",
      "provider": "Google",
      "cost": "free"
    },
    // ... 4 more models
  ]
}
```

#### `POST /chat`
**Primary endpoint:** Send prompt to multiple models in parallel.

**Request:**
```json
{
  "prompt": "Explain quantum computing in simple terms",
  "models": ["gemini", "llama-70b", "llama-8b", "mixtral", "deepseek"],
  "temperature": 0.7,
  "max_tokens": 512
}
```

**Response:**
```json
{
  "responses": [
    {
      "model": "gemini",
      "response": "Quantum computing uses quantum mechanics principles...",
      "tokens": 145,
      "latency_ms": 892,
      "error": null
    },
    {
      "model": "llama-70b",
      "response": "Quantum computers leverage superposition and entanglement...",
      "tokens": 163,
      "latency_ms": 1105,
      "error": null
    },
    {
      "model": "deepseek",
      "response": "",
      "tokens": null,
      "latency_ms": 234,
      "error": "Rate limit exceeded"
    }
    // ... other models
  ],
  "total_latency_ms": 1650
}
```

**Notes:**
- `models` field: array of model IDs to query
- `temperature`: 0.0-1.0 (default 0.7)
- `max_tokens`: max response length (default 512)
- `latency_ms`: time taken by that specific model
- `total_latency_ms`: time for entire request (should be ~= slowest model due to parallelization)

#### `POST /chat/{model_id}` (Optional)
Single model chat endpoint for testing individual models.

**Request:** Same as `/chat` but without `models` field
**Response:** Single `ModelResponse` object

---

## Data Models (Pydantic)

### Request Schema
```python
class ChatRequest(BaseModel):
    prompt: str
    models: List[str]  # ["gemini", "llama-70b", etc.]
    temperature: float = 0.7  # 0.0-1.0
    max_tokens: int = 512
```

### Response Schema
```python
class ModelResponse(BaseModel):
    model: str  # model ID
    response: str  # generated text
    tokens: Optional[int]  # token count (if available)
    latency_ms: int  # response time in milliseconds
    error: Optional[str]  # error message if failed

class ChatResponse(BaseModel):
    responses: List[ModelResponse]
    total_latency_ms: int
```

---

## Architecture Guidelines

### Project Structure
Use clean separation of concerns. Suggested structure:
```
coro/
├── backend/
│   ├── main.py           # FastAPI app
│   ├── config.py         # Configuration
│   ├── requirements.txt
│   ├── .env.example
│   ├── Procfile
│   ├── routers/          # API endpoints
│   ├── services/         # LLM client services
│   └── models/           # Pydantic schemas
```

But feel free to organize differently if you have better ideas.

### Code Quality
- Use **async/await** throughout (FastAPI is async)
- **Type hints** on all functions
- **Docstrings** for public functions
- **Error handling** that doesn't crash the app

### Environment Variables
Required in `.env`:
```env
GEMINI_API_KEY=your_key
GROQ_API_KEY=your_key
DEEPSEEK_API_KEY=your_key
```

### CORS Configuration
Enable CORS for all origins (will restrict later):
```python
allow_origins=["*"]
```

---

## Success Criteria

Phase 1 is complete when:

1. ✅ All 5 models respond successfully to test prompts
2. ✅ Parallel execution works (total time ~= slowest model, not sum)
3. ✅ One model failing doesn't break others
4. ✅ Response times: fastest < 2s, slowest < 5s, total < 6s
5. ✅ API documented (auto-generated OpenAPI docs at `/docs`)
6. ✅ Deployable to Railway/Render
7. ✅ Health check endpoint works
8. ✅ Clean error messages for invalid requests

---

## Testing

Verify with these test cases:

### 1. All models work
```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is 2+2?",
    "models": ["gemini", "llama-70b", "llama-8b", "mixtral", "deepseek"]
  }'
```
Expected: All 5 models return "4" (or similar)

### 2. Parallel execution
Check that `total_latency_ms` is roughly equal to the highest individual `latency_ms`, not the sum.

### 3. Error handling
Temporarily use invalid API key for one model. Verify:
- Request still succeeds (HTTP 200)
- Failed model has `error` field populated
- Other models still return results

### 4. OpenAPI docs
Visit `http://localhost:8000/docs` - should show interactive API documentation.

---

## Deployment

### Railway (Recommended)
1. Push code to GitHub
2. Connect Railway to repository
3. Add environment variables in Railway dashboard
4. Railway auto-detects Python and deploys
5. Get public URL: `https://your-app.up.railway.app`

### Render (Alternative)
1. Push code to GitHub
2. Create Web Service in Render
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables
6. Deploy

---

## API Keys Setup

### Google Gemini
1. Visit: https://aistudio.google.com/
2. Click "Get API key"
3. Create project (if needed)
4. Generate key

### Groq
1. Visit: https://console.groq.com/
2. Sign up/Login
3. Go to "API Keys"
4. Create new key

### DeepSeek
1. Visit: https://platform.deepseek.com/
2. Sign up/Login
3. Go to API Keys
4. Create new key

---

## Implementation Notes

### For Gemini Service
- Use `google.generativeai` SDK
- Model: `gemini-1.5-flash`
- Configure temperature and max_output_tokens

### For Groq Service
- Use `groq` SDK
- One service can handle all 3 Groq models
- Pass model name as parameter: `llama-3.1-70b-versatile`, `llama-3.1-8b-instant`, `mixtral-8x7b-32768`

### For DeepSeek Service
- No official SDK - use `httpx` for HTTP requests
- Endpoint: `POST https://api.deepseek.com/v1/chat/completions`
- Authorization: `Bearer YOUR_API_KEY`
- Model: `deepseek-chat`

### Latency Measurement
Measure from start of API call to completion:
```python
start = time.time()
# ... API call
latency_ms = int((time.time() - start) * 1000)
```

---

## Future Phases (For Context)

This is Phase 1 only. Future phases will add:
- **Phase 2:** Self-hosted Llama model via Modal.com
- **Phase 3:** iOS SwiftUI app
- **Phase 4:** Streaming, conversation history, analytics

Don't implement these now - focus on Phase 1.

---

## Notes

- Implement with **FastAPI best practices**
- Use your judgment for code organization
- Prioritize working code over perfect code
- Document any assumptions or decisions made

**Ready to implement!**
