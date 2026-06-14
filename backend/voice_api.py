"""
Voice API — SmartAid / MediConnect
Provides two endpoints exclusively powered by Groq:
  POST /api/voice/stt  — Speech-to-Text (Groq Whisper large-v3)
  POST /api/voice/tts  — Text-to-Speech (Groq PlayAI TTS)

Audio delivery: base64-encoded bytes in JSON (no file I/O on disk).
TTS: always attempted for all languages; Groq TTS does its best.
"""

import os
import base64
import logging
import pathlib
import io

from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional

from dotenv import load_dotenv

_env_path = pathlib.Path(__file__).resolve().parent / ".env"
load_dotenv(_env_path, override=False)

logger = logging.getLogger(__name__)

# ── Groq Models ────────────────────────────────────────────────────────────────
STT_MODEL = "whisper-large-v3"          # Groq Whisper — auto-detects language
TTS_MODEL = "playai-tts"                # Groq PlayAI TTS
TTS_VOICE = "Fritz-PlayAI"             # Default English voice
TTS_RESPONSE_FORMAT = "wav"            # WAV is widely compatible

# Language-to-locale map for Whisper prompt hints
_LANG_HINTS: dict[str, str] = {
    "en": "English",
    "hi": "Hindi",
    "ta": "Tamil",
    "kn": "Kannada",
    "te": "Telugu",
}

voice_router = APIRouter(prefix="/api/voice", tags=["Voice AI"])


# ── Helpers ────────────────────────────────────────────────────────────────────

def _get_groq_client():
    """Return a configured Groq client or raise RuntimeError."""
    try:
        from groq import Groq
    except ImportError:
        raise RuntimeError("groq package not installed. Run: pip install groq")

    api_key = os.environ.get("GROQ_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("GROQ_API_KEY is not set in environment.")
    return Groq(api_key=api_key)


# ── Request/Response Models ────────────────────────────────────────────────────

class TTSRequest(BaseModel):
    text: str = Field(..., min_length=1, max_length=4096, description="Text to synthesise into speech")
    language: Optional[str] = Field("en", description="ISO-639-1 language code: en, hi, ta, kn, te")


class STTResponse(BaseModel):
    text: str
    language_detected: Optional[str] = None


class TTSResponse(BaseModel):
    audio_base64: str
    audio_format: str = TTS_RESPONSE_FORMAT


# ── Endpoints ──────────────────────────────────────────────────────────────────

@voice_router.post(
    "/stt",
    response_model=STTResponse,
    summary="Speech-to-Text via Groq Whisper",
    description=(
        "Upload an audio file (WAV, M4A, MP3, WebM, OGG). "
        "Returns the transcribed text. Language is auto-detected by Whisper."
    ),
)
async def speech_to_text(
    audio: UploadFile = File(..., description="Audio file to transcribe"),
    language: Optional[str] = None,
):
    """
    Accepts multipart audio upload → Groq Whisper transcription → plain text.
    Supported languages: English, Hindi, Tamil, Kannada, Telugu (auto-detected).
    """
    # ── Validate ────────────────────────────────────────────────────────────────
    max_size_bytes = 25 * 1024 * 1024  # Groq Whisper limit: 25 MB
    audio_bytes = await audio.read()
    if len(audio_bytes) == 0:
        raise HTTPException(status_code=422, detail="Uploaded audio file is empty.")
    if len(audio_bytes) > max_size_bytes:
        raise HTTPException(
            status_code=413,
            detail=f"Audio file too large ({len(audio_bytes)} bytes). Limit: 25 MB."
        )

    # ── Resolve filename / MIME ─────────────────────────────────────────────────
    filename = audio.filename or "audio.wav"
    # Ensure a recognised extension so Groq accepts it
    ext = pathlib.Path(filename).suffix.lower()
    if ext not in {".wav", ".mp3", ".m4a", ".ogg", ".webm", ".flac", ".mp4"}:
        filename = f"audio.wav"

    # ── Build optional Whisper prompt from language hint ────────────────────────
    prompt = None
    if language and language in _LANG_HINTS:
        prompt = f"The speaker is speaking in {_LANG_HINTS[language]}."

    # ── Call Groq Whisper ───────────────────────────────────────────────────────
    try:
        client = _get_groq_client()
        logger.info(f"🎙️ STT request | size={len(audio_bytes)}B | file={filename} | lang={language}")

        transcription = client.audio.transcriptions.create(
            model=STT_MODEL,
            file=(filename, io.BytesIO(audio_bytes)),
            response_format="verbose_json",
            prompt=prompt,
            temperature=0.0,
        )

        text = (transcription.text or "").strip()
        detected_lang = getattr(transcription, "language", None)

        logger.info(f"✅ STT complete | detected_lang={detected_lang} | text_preview={text[:60]!r}")

        if not text:
            return JSONResponse(
                status_code=200,
                content={"text": "", "language_detected": detected_lang},
            )

        return STTResponse(text=text, language_detected=detected_lang)

    except RuntimeError as e:
        logger.error(f"❌ STT config error: {e}")
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.exception("❌ STT Groq error")
        raise HTTPException(status_code=500, detail=f"Speech recognition failed: {e}")


@voice_router.post(
    "/tts",
    response_model=TTSResponse,
    summary="Text-to-Speech via Groq PlayAI",
    description=(
        "Convert text to speech using Groq PlayAI TTS. "
        "Returns WAV audio encoded as base64."
    ),
)
async def text_to_speech(payload: TTSRequest):
    """
    Accepts JSON {text, language} → Groq PlayAI TTS → base64 WAV audio.
    TTS is attempted for all languages (EN/HI/TA/KN/TE).
    """
    # ── Sanitise input ──────────────────────────────────────────────────────────
    text = payload.text.strip()
    if not text:
        raise HTTPException(status_code=422, detail="Text field is empty.")

    # ── Call Groq TTS ───────────────────────────────────────────────────────────
    try:
        client = _get_groq_client()
        logger.info(f"🔊 TTS request | lang={payload.language} | chars={len(text)} | preview={text[:60]!r}")

        response = client.audio.speech.create(
            model=TTS_MODEL,
            voice=TTS_VOICE,
            input=text,
            response_format=TTS_RESPONSE_FORMAT,
        )

        # The Groq SDK streams bytes; collect them
        audio_bytes = response.read()
        if not audio_bytes:
            raise RuntimeError("Groq TTS returned empty audio.")

        audio_b64 = base64.b64encode(audio_bytes).decode("utf-8")

        logger.info(f"✅ TTS complete | audio_size={len(audio_bytes)}B | b64_len={len(audio_b64)}")
        return TTSResponse(audio_base64=audio_b64, audio_format=TTS_RESPONSE_FORMAT)

    except RuntimeError as e:
        logger.error(f"❌ TTS config error: {e}")
        raise HTTPException(status_code=503, detail=str(e))
    except Exception as e:
        logger.exception("❌ TTS Groq error")
        raise HTTPException(status_code=500, detail=f"Text-to-speech failed: {e}")


@voice_router.get("/health", summary="Voice API health check")
async def voice_health():
    """Check if Groq API key is configured and the voice endpoints are available."""
    api_key = os.environ.get("GROQ_API_KEY", "").strip()
    return {
        "status": "ok" if api_key else "degraded",
        "groq_key_present": bool(api_key),
        "stt_model": STT_MODEL,
        "tts_model": TTS_MODEL,
        "tts_voice": TTS_VOICE,
        "supported_languages": list(_LANG_HINTS.keys()),
    }
