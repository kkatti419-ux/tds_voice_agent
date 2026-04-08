# Backend (FastAPI)

This backend provides an echo API:

- `POST /voice` (non-streaming): returns `{ text, audio_url }` where `audio_url` is the same uploaded voice
- `WS /ws/voice` (streaming): receives audio and sends back `audio_url` for the same audio

## Prerequisites

- Python 3.10+

## Setup

```bash
cd backend
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

export PUBLIC_BASE_URL="http://localhost:8000"

uvicorn main:app --reload --port 8000
```

## WebSocket protocol

Client -> Server:
```json
{ "type": "audio", "audio_base64": "....", "mime": "audio/wav" }
```

Server -> Client:
```json
{ "type": "text_delta", "delta": "Echoing your voice..." }
{ "type": "audio_url", "audio_url": "http://localhost:8000/audio/<saved-file>" }
{ "type": "done", "text": "Echo complete" }
```

