import base64
import json
import os
import tempfile
import uuid
from pathlib import Path

from fastapi import FastAPI, UploadFile, WebSocket, WebSocketDisconnect
from fastapi.staticfiles import StaticFiles

app = FastAPI()

BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://localhost:8000")

backend_dir = Path(__file__).parent
audio_dir = backend_dir / "static" / "audio"
audio_dir.mkdir(parents=True, exist_ok=True)

app.mount("/audio", StaticFiles(directory=str(audio_dir)), name="audio")


def _guess_extension(mime: str, filename: str = "") -> str:
    mime_l = (mime or "").lower()
    filename_l = (filename or "").lower()
    if "wav" in mime_l or filename_l.endswith(".wav"):
        return ".wav"
    if "webm" in mime_l or filename_l.endswith(".webm"):
        return ".webm"
    if "mp3" in mime_l or filename_l.endswith(".mp3"):
        return ".mp3"
    if "ogg" in mime_l or filename_l.endswith(".ogg"):
        return ".ogg"
    return ".wav"


def _store_audio_bytes(audio_bytes: bytes, ext: str) -> str:
    filename = f"{uuid.uuid4().hex}{ext}"
    out_path = audio_dir / filename
    out_path.write_bytes(audio_bytes)
    return f"{BASE_URL}/audio/{filename}"


@app.get("/health")
def health():
    return {"ok": True}


@app.post("/voice")
async def voice(file: UploadFile):
    """
    Non-streaming echo endpoint:
    - receives uploaded voice file
    - returns same file URL as audio_url
    """
    ext = _guess_extension(file.content_type or "", file.filename or "")
    with tempfile.NamedTemporaryFile(delete=False, suffix=ext) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name

    try:
        audio_bytes = Path(tmp_path).read_bytes()
        audio_url = _store_audio_bytes(audio_bytes, ext)
        return {"text": "Echo voice", "audio_url": audio_url}
    finally:
        try:
            Path(tmp_path).unlink(missing_ok=True)
        except Exception:
            pass


@app.websocket("/ws/voice")
async def ws_voice(ws: WebSocket):
    """
    Streaming echo endpoint:
    - Client sends: {"type":"audio","audio_base64":"...","mime":"audio/wav"}
    - Server sends:
      * {"type":"text_delta","delta":"Echoing your voice..."}
      * {"type":"audio_url","audio_url":"http://.../audio/<same-file>"}
      * {"type":"done","text":"Echo complete"}
    """
    await ws.accept()

    try:
        raw = await ws.receive_text()
        data = json.loads(raw)
        if data.get("type") != "audio":
            await ws.send_text(json.dumps({"type": "error", "error": "Expected type=audio"}))
            await ws.close()
            return

        audio_b64 = data["audio_base64"]
        mime = data.get("mime", "audio/wav")

        audio_bytes = base64.b64decode(audio_b64)
        ext = _guess_extension(mime)
        audio_url = _store_audio_bytes(audio_bytes, ext)

        await ws.send_text(json.dumps({"type": "text_delta", "delta": "Echoing your voice..."}))
        await ws.send_text(json.dumps({"type": "audio_url", "audio_url": audio_url}))
        await ws.send_text(json.dumps({"type": "done", "text": "Echo complete"}))
        await ws.close()

    except WebSocketDisconnect:
        return
    except Exception as e:
        try:
            await ws.send_text(json.dumps({"type": "error", "error": str(e)}))
        except Exception:
            pass
        try:
            await ws.close()
        except Exception:
            pass

