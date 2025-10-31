# CORO - Multi-LLM Chat Hub 🎵

Compare responses from multiple AI models side-by-side.

## Overview

**CORO** (meaning "Chorus") allows you to send a single prompt to multiple Large Language Models simultaneously and compare their responses. This helps you understand the strengths, weaknesses, and characteristics of different models for your specific use cases.

### Integrated Models (Phase 1)

1. **Google Gemini 1.5 Flash** - Fast, efficient, free
2. **Llama 3.1 70B** (via Groq) - Large model, ultra-fast inference
3. **Llama 3.1 8B** (via Groq) - Smaller, faster variant
4. **Mixtral 8x7B** (via Groq) - Mixture-of-experts architecture
5. **DeepSeek V2.5** - Strong at coding and reasoning

## Quick Start

### Prerequisites

- Python 3.11 or higher
- pip (Python package manager)
- API keys for:
  - Google Gemini
  - Groq
  - DeepSeek

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/coro.git
   cd coro/backend
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set up environment variables**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add your API keys:
   ```env
   GEMINI_API_KEY=your_gemini_key
   GROQ_API_KEY=your_groq_key
   DEEPSEEK_API_KEY=your_deepseek_key
   ```

4. **Run the server**
   ```bash
   uvicorn main:app --reload
   ```
   
   The API will be available at `http://localhost:8000`

### Testing

Visit `http://localhost:8000/docs` for interactive API documentation (Swagger UI).

Or test with curl:

```bash
# Health check
curl http://localhost:8000/health

# List available models
curl http://localhost:8000/models

# Chat with multiple models
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing in one sentence",
    "models": ["gemini", "llama-70b", "deepseek"],
    "temperature": 0.7,
    "max_tokens": 100
  }'
```

## API Documentation

### Endpoints

#### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-30T12:34:56Z"
}
```

#### `GET /models`
List all available models.

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
    // ... more models
  ]
}
```

#### `POST /chat`
Send a prompt to multiple models in parallel.

**Request:**
```json
{
  "prompt": "Write a haiku about programming",
  "models": ["gemini", "llama-70b", "llama-8b", "mixtral", "deepseek"],
  "temperature": 0.8,
  "max_tokens": 100
}
```

**Response:**
```json
{
  "responses": [
    {
      "model": "gemini",
      "response": "Code flows like water...",
      "tokens": 23,
      "latency_ms": 892,
      "error": null
    },
    {
      "model": "llama-70b",
      "response": "Fingers dance on keys...",
      "tokens": 25,
      "latency_ms": 1105,
      "error": null
    }
  ],
  "total_latency_ms": 1650
}
```

#### `POST /chat/{model_id}`
Send a prompt to a single model.

**Path Parameters:**
- `model_id`: One of `gemini`, `llama-70b`, `llama-8b`, `mixtral`, `deepseek`

**Request:**
```json
{
  "prompt": "What is the capital of France?",
  "temperature": 0.7,
  "max_tokens": 50
}
```

## Getting API Keys

### Google Gemini
1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Click "Get API key"
3. Create a new project (if needed)
4. Generate and copy the API key

**Free tier:** 15 requests/minute

### Groq
1. Go to [Groq Console](https://console.groq.com/)
2. Sign up / Log in
3. Navigate to "API Keys"
4. Create new key
5. Copy the key

**Free tier:** 30 requests/minute

### DeepSeek
1. Go to [DeepSeek Platform](https://platform.deepseek.com/)
2. Sign up / Log in
3. Go to API Keys section
4. Create new key
5. Copy the key

**Cost:** ~$0.14 per 1M tokens (nearly free)

## Project Structure

```
coro/
├── backend/
│   ├── main.py                    # FastAPI application
│   ├── config.py                  # Configuration management
│   ├── requirements.txt           # Python dependencies
│   ├── .env.example              # Environment template
│   ├── Procfile                  # Deployment config
│   │
│   ├── routers/
│   │   └── chat.py               # Chat endpoints
│   │
│   ├── services/
│   │   ├── gemini_service.py     # Gemini integration
│   │   ├── groq_service.py       # Groq integration
│   │   └── deepseek_service.py   # DeepSeek integration
│   │
│   └── models/
│       └── schemas.py            # Pydantic models
│
├── .clinerules                    # Claude Code context
└── README.md
```

## Deployment

### Railway

1. Push your code to GitHub
2. Go to [Railway.app](https://railway.app/)
3. Create new project from GitHub repository
4. Add environment variables:
   - `GEMINI_API_KEY`
   - `GROQ_API_KEY`
   - `DEEPSEEK_API_KEY`
5. Railway auto-deploys from `Procfile`

Your API will be available at: `https://your-app.up.railway.app`

### Render

1. Push code to GitHub
2. Go to [Render.com](https://render.com/)
3. Create new Web Service
4. Connect GitHub repository
5. Set build command: `pip install -r requirements.txt`
6. Set start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
7. Add environment variables
8. Deploy

## Development

### Running Tests

```bash
# Install dev dependencies
pip install pytest httpx

# Run tests
pytest tests/
```

### Code Style

We use:
- **Type hints** on all functions
- **Async/await** throughout
- **Pydantic** for data validation
- **Docstrings** for documentation

Example:
```python
async def generate_response(
    prompt: str,
    temperature: float = 0.7,
    max_tokens: int = 512
) -> ModelResponse:
    """
    Generate a response from the model.
    
    Args:
        prompt: User's input text
        temperature: Sampling temperature (0.0-1.0)
        max_tokens: Maximum tokens in response
        
    Returns:
        ModelResponse with generated text and metadata
    """
    # Implementation
```

## Architecture

### Request Flow

```
Client (iOS/Web)
    ↓ HTTP POST /chat
FastAPI Router
    ↓ Parallel execution (asyncio.gather)
┌─────────┬──────────┬────────────┬─────────┐
Gemini   Llama-70B  Llama-8B    DeepSeek
Service  Service    Service     Service
    ↓         ↓          ↓          ↓
Google    Groq API   Groq API   DeepSeek
API                              API
```

### Error Handling

- **Model-level errors**: One model failing doesn't affect others
- **Request-level errors**: Proper HTTP status codes (400, 500, 503)
- **Graceful degradation**: Returns partial results if some models succeed

## Performance

### Latency Targets
- Fastest model: < 2 seconds (typically Groq)
- Slowest model: < 5 seconds
- Total (all 5 parallel): < 6 seconds

### Rate Limits
- Gemini: 15 req/min (free tier)
- Groq: 30 req/min (free tier)
- DeepSeek: ~100 req/min (paid but cheap)

## Roadmap

### Phase 1 ✅ (Current)
- [x] FastAPI backend
- [x] 5 model integrations
- [x] Parallel execution
- [x] Error handling
- [x] Deployment ready

### Phase 2 (Next)
- [ ] Self-hosted model via Modal.com
- [ ] llama.cpp integration
- [ ] Learn GPU inference

### Phase 3 (Future)
- [ ] iOS SwiftUI app
- [ ] Chat interface
- [ ] Model comparison UI

### Phase 4+ (Future)
- [ ] Streaming responses (SSE)
- [ ] Conversation history
- [ ] Advanced analytics

## Troubleshooting

### "Module not found" errors
```bash
pip install -r requirements.txt
```

### "API key not found" errors
Make sure `.env` file exists and contains all required keys:
```bash
cp .env.example .env
# Edit .env with your keys
```

### Rate limit errors
- Wait a minute and try again
- Reduce number of models in request
- Use fewer requests per minute

### CORS errors (from browser)
CORS is configured to allow all origins in development. In production, update `config.py`:
```python
cors_origins: list[str] = ["https://your-frontend-domain.com"]
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

- Documentation: See `CORO_PHASE_1_SPECIFICATION.md`
- API Docs: `/docs` endpoint when server is running
- Issues: GitHub Issues

---

**Built with ❤️ for comparing LLMs**
