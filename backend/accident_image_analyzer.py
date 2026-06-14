"""
SmartAid Accident Image Analysis Module
Uses Google Gemini API to analyze accident scene images.

Workflow:
  1. User uploads accident image
  2. Image is loaded and sent to Gemini Vision Model
  3. AI extracts accident features (people, vehicles, injuries, fire, damage)
  4. Severity level predicted
  5. Ambulance alert priority returned
"""

import os
import io
import json
import re
import pathlib
import logging
from typing import Optional
from PIL import Image

# Safety net: ensure .env is loaded
from dotenv import load_dotenv
_env_path = pathlib.Path(__file__).resolve().parent / ".env"
load_dotenv(_env_path, override=False)

logger = logging.getLogger(__name__)

# Model config
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-1.5-flash")

# System prompt sent to the vision model
ANALYSIS_PROMPT = """You are an AI emergency accident analysis system used in a SmartAid platform.

Analyze the uploaded accident scene image carefully and estimate the severity of the accident.

Your tasks:

1. Count the number of people visible in the accident scene.
2. Count the number of vehicles involved (car, truck, bike, bus).
3. Detect if there is any fire, smoke, or explosion risk.
4. Identify possible injured persons (lying on ground, unconscious posture, severe damage).
5. Estimate the vehicle damage level from 1 to 5:
   1 = very minor
   2 = minor
   3 = moderate
   4 = severe
   5 = catastrophic

6. Estimate the overall accident severity level:
   - LOW
   - MEDIUM
   - CRITICAL

Severity rules:
LOW → minor damage, few people, no fire
MEDIUM → multiple vehicles or injured persons
CRITICAL → major crash, fire, multiple injured people

Return ONLY a valid JSON response with this structure:

{
  "people_detected": number,
  "vehicles_detected": number,
  "possible_injured": number,
  "fire_detected": true/false,
  "damage_level": number,
  "severity_level": "LOW | MEDIUM | CRITICAL",
  "ambulance_priority": "LOW | MEDIUM | HIGH"
}

Do not include explanations. Only return JSON."""


def _get_gemini_client():
    """Lazily import and configure Gemini client."""
    api_key = os.environ.get("GEMINI_API_KEY", "").strip() or os.environ.get("GOOGLE_API_KEY", "").strip()
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY is not set")
    try:
        import google.generativeai as genai
        genai.configure(api_key=api_key)
        return genai
    except ImportError:
        raise RuntimeError(
            "The 'google-generativeai' package is not installed. "
            "Install it with: pip install google-generativeai"
        )


def _extract_json(text: str) -> dict:
    """
    Extract the first JSON object from a model response that might
    contain markdown fences or extra text around it.
    """
    # Try direct parse first
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Try to find JSON block in markdown fences
    md_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if md_match:
        return json.loads(md_match.group(1))

    # Try to find first { ... } block
    brace_match = re.search(r"\{.*\}", text, re.DOTALL)
    if brace_match:
        return json.loads(brace_match.group(0))

    raise ValueError(f"Could not extract JSON from model response: {text[:200]}")


def _validate_result(data: dict) -> dict:
    """Validate and normalise the AI response into the expected schema."""
    result = {
        "people_detected": int(data.get("people_detected", 0)),
        "vehicles_detected": int(data.get("vehicles_detected", 0)),
        "possible_injured": int(data.get("possible_injured", 0)),
        "fire_detected": bool(data.get("fire_detected", False)),
        "damage_level": max(1, min(5, int(data.get("damage_level", 1)))),
        "severity_level": str(data.get("severity_level", "LOW")).upper(),
        "ambulance_priority": str(data.get("ambulance_priority", "LOW")).upper(),
    }

    # Clamp severity to valid values
    if result["severity_level"] not in ("LOW", "MEDIUM", "CRITICAL"):
        result["severity_level"] = "MEDIUM"
    if result["ambulance_priority"] not in ("LOW", "MEDIUM", "HIGH"):
        result["ambulance_priority"] = "MEDIUM"

    return result


def _compress_image(image_bytes: bytes, max_size: int = 800, quality: int = 70) -> bytes:
    """Resize the image to fit within max_size and save it as a compressed JPEG."""
    try:
        from PIL import Image
        img = Image.open(io.BytesIO(image_bytes))
        if img.mode != "RGB":
            img = img.convert("RGB")
            
        width, height = img.size
        if width > max_size or height > max_size:
            if width > height:
                new_width = max_size
                new_height = int(height * (max_size / width))
            else:
                new_height = max_size
                new_width = int(width * (max_size / height))
            img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
            
        out_buf = io.BytesIO()
        img.save(out_buf, format="JPEG", quality=quality)
        compressed = out_buf.getvalue()
        logger.info(f"Image compressed from {len(image_bytes)} to {len(compressed)} bytes.")
        return compressed
    except Exception as e:
        logger.warning(f"Failed to compress image, using original: {e}")
        return image_bytes


def analyze_accident_image(image_bytes: bytes, mime_type: str = "image/jpeg") -> dict:
    """
    Analyze an accident scene image using the Gemini API.

    Parameters
    ----------
    image_bytes : bytes
        Raw bytes of the image file (JPEG / PNG).
    mime_type : str
        MIME type of the image, e.g. "image/jpeg" or "image/png".

    Returns
    -------
    dict
        A dict with keys: people_detected, vehicles_detected,
        possible_injured, fire_detected, damage_level,
        severity_level, ambulance_priority.
    """
    logger.info("🔍 Starting accident image analysis via Gemini ...")

    genai = _get_gemini_client()

    # Compress image to optimize latency
    compressed_bytes = _compress_image(image_bytes)
    
    # Load image for SDK
    image = Image.open(io.BytesIO(compressed_bytes))

    # Call Gemini API
    model = genai.GenerativeModel(
        model_name=GEMINI_MODEL,
        generation_config={"response_mime_type": "application/json"}
    )
    response = model.generate_content([ANALYSIS_PROMPT, image])

    raw_text = response.text.strip()
    logger.info(f"📝 Raw model response: {raw_text[:300]}")

    parsed = _extract_json(raw_text)
    result = _validate_result(parsed)

    logger.info(f"✅ Analysis complete — severity={result['severity_level']}, priority={result['ambulance_priority']}")
    return result


def analyze_accident_image_from_file(file_path: str) -> dict:
    """Convenience wrapper that reads a file from disk and analyses it."""
    import mimetypes

    mime, _ = mimetypes.guess_type(file_path)
    if mime is None:
        mime = "image/jpeg"

    with open(file_path, "rb") as f:
        return analyze_accident_image(f.read(), mime_type=mime)
