# CORO Backend - Phase 1

Multi-LLM chat application backend built with FastAPI. Compare responses from 5 different AI models side-by-side.

## Features

- **5 LLM Integrations**: Gemini 1.5 Flash, Llama 3.1 70B, Llama 3.1 8B, Mixtral 8x7B, DeepSeek V2.5
- **Parallel Execution**: Send prompts to multiple models simultaneously
- **Independent Error Handling**: One model failure doesn't break others
- **Production Ready**: Deployable to Railway/Render
- **Auto-generated API Docs**: Available at `/docs`

## Prerequisites

- Python 3.11+
- API keys for:
  - Google Gemini ([Get here](https://aistudio.google.com/))
  - Groq ([Get here](https://console.groq.com/))
  - DeepSeek ([Get here](https://platform.deepseek.com/))

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure Environment Variables

```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your API keys
# GEMINI_API_KEY=your_key_here
# GROQ_API_KEY=your_key_here
# DEEPSEEK_API_KEY=your_key_here
```

### 3. Run the Server

```bash
# From the backend directory
python main.py

# Or use uvicorn directly
uvicorn backend.main:app --reload
```

The server will start at `http://localhost:8000`

### 4. Test the API

Visit `http://localhost:8000/docs` for interactive API documentation.

## API Endpoints

### `GET /health`
Health check endpoint.

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2025-10-30T12:00:00Z"
}
```

### `GET /models`
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
    ...
  ]
}
```

### `POST /chat`
Send prompt to multiple models in parallel.

**Request:**
```json
{
  "prompt": "What is 2+2?",
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
      "response": "2 + 2 = 4",
      "tokens": 8,
      "latency_ms": 892,
      "error": null
    },
    ...
  ],
  "total_latency_ms": 1650
}
```

### `POST /chat/{model_id}`
Send prompt to a single model.

**Request:**
```json
{
  "prompt": "What is 2+2?",
  "temperature": 0.7,
  "max_tokens": 512
}
```

**Response:** Single `ModelResponse` object

## Testing

### Test All Models

```bash
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "What is 2+2?",
    "models": ["gemini", "llama-70b", "llama-8b", "mixtral", "deepseek"]
  }'
```

### Test Single Model

```bash
curl -X POST http://localhost:8000/chat/gemini \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Explain quantum computing in simple terms",
    "temperature": 0.7,
    "max_tokens": 512
  }'
```

## Project Structure

```
backend/
├── main.py              # FastAPI application
├── config.py            # Configuration management
├── requirements.txt     # Python dependencies
├── .env.example         # Environment variables template
├── Procfile            # Deployment configuration
├── models/             # Pydantic schemas
│   └── schemas.py
├── services/           # LLM client services
│   ├── gemini_service.py
│   ├── groq_service.py
│   └── deepseek_service.py
└── routers/            # API endpoints
    └── chat.py
```

## Deployment

### Railway

1. Push code to GitHub
2. Connect Railway to your repository
3. Add environment variables in Railway dashboard
4. Railway auto-detects Python and deploys
5. Get your public URL

### Render

1. Push code to GitHub
2. Create Web Service in Render
3. Build command: `pip install -r requirements.txt`
4. Start command: `uvicorn backend.main:app --host 0.0.0.0 --port $PORT`
5. Add environment variables
6. Deploy

## Performance Targets

- Fastest model: < 2s
- Slowest model: < 5s
- Total (all 5 models in parallel): < 6s

## Error Handling

The API is designed to be resilient:
- Individual model failures don't break the entire request
- Failed models return an `error` field in the response
- HTTP 500 only occurs if ALL models fail

## Development

### Adding a New Model

1. Add model configuration to `config.py`
2. Create service client in `services/`
3. Update router logic in `routers/chat.py`
4. Update documentation

## License

MIT
