"""
Sarvam AI Service Module — LifeLink / MediConnect
Provides:
  1. Translation (Indian languages to English/Hinglish/etc.)
  2. Speech-to-Text (STT) for Indian languages
  3. Text-to-Speech (TTS) for Indian languages
"""

import os
import pathlib
import logging
import httpx
from typing import Optional

# Load .env variables
from dotenv import load_dotenv
_env_path = pathlib.Path(__file__).resolve().parent / ".env"
load_dotenv(_env_path, override=False)

logger = logging.getLogger(__name__)

SARVAM_API_KEY = os.environ.get("SARVAM_API_KEY", "").strip()

logger.info("=" * 50)
logger.info("SARVAM AI CONFIGURATION")
logger.info("=" * 50)
logger.info(f"SARVAM_API_KEY_PRESENT={bool(SARVAM_API_KEY)}")
if SARVAM_API_KEY:
    logger.info(f"SARVAM_API_KEY_PREFIX={SARVAM_API_KEY[:8]}****")
logger.info("=" * 50)

if not SARVAM_API_KEY:
    logger.warning("⚠️ SARVAM_API_KEY not set. Sarvam services will fail.")

def translate_text(
    text: str,
    source_lang: str = "hi-IN",
    target_lang: str = "en-IN"
) -> dict:
    """
    Translate text using Sarvam AI Mayura Translation API.
    
    Parameters
    ----------
    text : str
        The input text to translate.
    source_lang : str
        Source language code (e.g., hi-IN, ta-IN, te-IN).
    target_lang : str
        Target language code (default is en-IN).
    """
    if not SARVAM_API_KEY:
        raise ValueError("SARVAM_API_KEY is not configured.")
        
    url = "https://api.sarvam.ai/translate"
    headers = {
        "api-subscription-key": SARVAM_API_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "input": text,
        "source_language_code": source_lang,
        "target_language_code": target_lang,
        "model": "mayura:v1"
    }
    
    logger.info(f"Translating text: '{text[:50]}' from {source_lang} to {target_lang}")
    
    try:
        with httpx.Client() as client:
            response = client.post(url, json=payload, headers=headers, timeout=15.0)
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Sarvam translation API failed: {e}")
        raise RuntimeError(f"Sarvam translation failed: {e}")

def speech_to_text(
    audio_bytes: bytes,
    filename: str = "audio.wav",
    language_code: str = "unknown",
    mode: str = "transcribe"
) -> dict:
    """
    Transcribe audio bytes using Sarvam AI Saaras STT API.
    
    Parameters
    ----------
    audio_bytes : bytes
        The raw audio file bytes.
    filename : str
        Audio filename (e.g. audio.wav, audio.mp3).
    language_code : str
        Language code (e.g. hi-IN, ta-IN, te-IN, or 'unknown' for auto-detect).
    mode : str
        Speech mode ('transcribe' or 'translate').
    """
    if not SARVAM_API_KEY:
        raise ValueError("SARVAM_API_KEY is not configured.")
        
    url = "https://api.sarvam.ai/speech-to-text"
    headers = {
        "api-subscription-key": SARVAM_API_KEY
    }
    
    files = {
        "file": (filename, audio_bytes, "audio/wav")
    }
    data = {
        "model": "saaras:v3",
        "mode": mode,
        "language_code": language_code
    }
    
    logger.info(f"Transcribing audio file: {filename} (size={len(audio_bytes)} bytes) with lang={language_code}")
    
    try:
        with httpx.Client() as client:
            response = client.post(url, headers=headers, files=files, data=data, timeout=45.0)
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Sarvam STT API failed: {e}")
        raise RuntimeError(f"Sarvam STT failed: {e}")

def text_to_speech(
    text: str,
    language_code: str = "hi-IN",
    speaker: str = "shubh"
) -> dict:
    """
    Convert text to speech audio using Sarvam AI Bulbul TTS API.
    
    Parameters
    ----------
    text : str
        Text to convert.
    language_code : str
        Language code (e.g., hi-IN, ta-IN, te-IN).
    speaker : str
        Speaker voice identifier (default: 'shubh').
    """
    if not SARVAM_API_KEY:
        raise ValueError("SARVAM_API_KEY is not configured.")
        
    url = "https://api.sarvam.ai/text-to-speech"
    headers = {
        "api-subscription-key": SARVAM_API_KEY,
        "Content-Type": "application/json"
    }
    payload = {
        "text": text,
        "speaker": speaker,
        "target_language_code": language_code,
        "pitch": 1,
        "pace": 1
    }
    
    logger.info(f"Generating TTS for text: '{text[:50]}' in {language_code} with voice {speaker}")
    
    try:
        with httpx.Client() as client:
            response = client.post(url, json=payload, headers=headers, timeout=20.0)
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Sarvam TTS API failed: {e}")
        raise RuntimeError(f"Sarvam TTS failed: {e}")
