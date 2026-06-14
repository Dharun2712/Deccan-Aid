"""
Groq AI Service Module — LifeLink / MediConnect
Exclusively uses: meta-llama/llama-4-scout-17b-16e-instruct

Provides:
  1. Accident Image Vision Analysis  (multimodal)
  2. First-Aid Chatbot               (text)
  3. Groq connectivity health check
"""

import os
import pathlib
import json
import re
import base64
import time
import logging
import traceback
from typing import Optional

# Safety net: ensure .env is loaded even if this module is imported directly
from dotenv import load_dotenv
_env_path = pathlib.Path(__file__).resolve().parent / ".env"
load_dotenv(_env_path, override=False)  # don't override if already loaded

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────
# Model Configuration  (single source of truth)
# ─────────────────────────────────────────────

VISION_MODEL = os.getenv(
    "VISION_MODEL",
    "llama-3.2-11b-vision-preview",
)
CHAT_MODEL = os.getenv(
    "CHAT_MODEL",
    "meta-llama/llama-4-scout-17b-16e-instruct",
)

# ─────────────────────────────────────────────
# Startup Diagnostics
# ─────────────────────────────────────────────
_startup_key = os.environ.get("GROQ_API_KEY", "")
_startup_vision_key = os.environ.get("GROQ_API_KEY_VISION", "")
logger.info("=" * 50)
logger.info("GROQ CONFIGURATION")
logger.info("=" * 50)
logger.info(f"GROQ_API_KEY_PRESENT={bool(_startup_key)}")
if _startup_key:
    logger.info(f"GROQ_API_KEY_PREFIX={_startup_key[:8]}****")
logger.info(f"GROQ_API_KEY_VISION_PRESENT={bool(_startup_vision_key)}")
if _startup_vision_key:
    logger.info(f"GROQ_API_KEY_VISION_PREFIX={_startup_vision_key[:8]}****")
logger.info(f"VISION_MODEL={VISION_MODEL}")
logger.info(f"CHAT_MODEL={CHAT_MODEL}")
logger.info("=" * 50)

if not _startup_key:
    logger.warning(
        "⚠️  GROQ_API_KEY not set. Chat services will fail."
    )
if not _startup_vision_key:
    logger.warning(
        "⚠️  GROQ_API_KEY_VISION not set. Image analysis will fall back to GROQ_API_KEY."
    )

# ─────────────────────────────────────────────
# Analysis Prompt  (emergency-response oriented)
# ─────────────────────────────────────────────
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


# ─────────────────────────────────────────────
# Internal Utilities
# ─────────────────────────────────────────────

def _get_groq_client(use_vision: bool = False):
    """Build and return a Groq client, raising RuntimeError on failure."""
    try:
        from groq import Groq
    except ImportError:
        raise RuntimeError(
            "The 'groq' package is not installed. "
            "Install it with: pip install groq"
        )
    # Read the key LIVE from the environment every time — never rely on a
    # module-level snapshot that may have been captured before load_dotenv.
    if use_vision:
        api_key = os.environ.get("GROQ_API_KEY_VISION", "").strip()
        if not api_key:
            api_key = os.environ.get("GROQ_API_KEY", "").strip()
    else:
        api_key = os.environ.get("GROQ_API_KEY", "").strip()

    if not api_key:
        logger.error(
            f"GROQ_API_KEY {'(vision)' if use_vision else ''} is not set in os.environ. "
            f"Checked .env at {_env_path} (exists={_env_path.exists()})"
        )
        raise RuntimeError("GROQ_API_KEY is not set")
    logger.debug(f"Groq client created with key prefix: {api_key[:8]}****")
    return Groq(api_key=api_key)


def _extract_json(text: str) -> dict:
    """
    Extract the first JSON object from a model response that may contain
    markdown fences or surrounding prose.
    """
    # Direct parse
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass

    # Markdown-fenced JSON block
    md_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if md_match:
        try:
            return json.loads(md_match.group(1))
        except json.JSONDecodeError:
            pass

    # First bare { … } block
    brace_match = re.search(r"\{.*\}", text, re.DOTALL)
    if brace_match:
        try:
            return json.loads(brace_match.group(0))
        except json.JSONDecodeError:
            pass

    raise ValueError(f"Could not extract JSON from model response: {text[:200]}")


def _validate_analysis_result(data: dict) -> dict:
    """Validate and normalise the AI response into the expected schema (plus compatibility keys)."""
    
    people_detected = int(data.get("people_detected", 0))
    vehicles_detected = int(data.get("vehicles_detected", 0))
    possible_injured = int(data.get("possible_injured", 0))
    fire_detected = bool(data.get("fire_detected", False))
    damage_level = max(1, min(5, int(data.get("damage_level", 1))))
    
    severity_level = str(data.get("severity_level", "LOW")).upper()
    if severity_level not in ("LOW", "MEDIUM", "CRITICAL"):
        severity_level = "MEDIUM"
        
    ambulance_priority = str(data.get("ambulance_priority", "LOW")).upper()
    if ambulance_priority not in ("LOW", "MEDIUM", "HIGH"):
        ambulance_priority = "MEDIUM"

    # Map damage level to vehicle damage string
    damage_map = {
        1: "very minor damage",
        2: "minor damage",
        3: "moderate damage",
        4: "severe damage",
        5: "catastrophic damage"
    }
    vehicle_damage_str = damage_map.get(damage_level, "unknown damage")

    # Combine new schema fields with legacy compatibility fields
    result = {
        # New keys requested by user
        "people_detected": people_detected,
        "vehicles_detected": vehicles_detected,
        "possible_injured": possible_injured,
        "fire_detected": fire_detected,
        "damage_level": damage_level,
        "severity_level": severity_level,
        "ambulance_priority": ambulance_priority,
        
        # Legacy/Compatibility keys expected by frontend or router
        "severity": severity_level.lower(),
        "vehicle_damage": vehicle_damage_str,
        "visible_injuries": f"{possible_injured} possible injured persons" if possible_injured > 0 else "none",
        "road_condition": "not determinable",
        "ambulance_required": fire_detected or possible_injured > 0 or severity_level in ("MEDIUM", "CRITICAL"),
        "recommended_response": f"Dispatch ambulance with priority {ambulance_priority}. People: {people_detected}, Vehicles: {vehicles_detected}",
        "confidence": 1.0,
    }
    return result


def _compress_image(image_bytes: bytes, max_size: int = 800, quality: int = 70) -> bytes:
    """Resize the image to fit within max_size and save it as a compressed JPEG."""
    try:
        from PIL import Image
        import io
        img = Image.open(io.BytesIO(image_bytes))
        
        # Convert to RGB if not already
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


# ─────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────

def analyze_accident_image_with_groq(
    image_bytes: bytes,
    mime_type: str = "image/jpeg",
) -> dict:
    """
    Analyze an accident scene image using Groq Vision
    (meta-llama/llama-4-scout-17b-16e-instruct).

    Parameters
    ----------
    image_bytes : bytes
        Raw bytes of the image (JPEG / PNG / WebP).
    mime_type : str
        MIME type of the image, e.g. "image/jpeg".

    Returns
    -------
    dict  — structured analysis with keys:
        severity, vehicle_damage, visible_injuries, road_condition,
        ambulance_required, recommended_response, confidence,
        severity_level (legacy), ambulance_priority (legacy).

    Raises
    ------
    RuntimeError  on any unrecoverable failure (no silent fallback).
    """
    logger.info(f"Using Groq model: {VISION_MODEL}")
    logger.info(
        f"📸 Image analysis request — size={len(image_bytes)} bytes, "
        f"type={mime_type}"
    )

    request_start = time.time()
    client = _get_groq_client(use_vision=True)

    # Compress the image before base64 encoding to reduce network latency
    # and improve vision model recognition reliability.
    compressed_bytes = _compress_image(image_bytes)
    # Since we save as JPEG in _compress_image, update mime_type to image/jpeg
    current_mime = "image/jpeg"

    # Encode image for the multimodal message
    image_b64 = base64.standard_b64encode(compressed_bytes).decode("utf-8")
    image_url = f"data:{current_mime};base64,{image_b64}"

    messages = [
        {
            "role": "user",
            "content": [
                {
                    "type": "image_url",
                    "image_url": {"url": image_url},
                },
                {
                    "type": "text",
                    "text": ANALYSIS_PROMPT,
                },
            ],
        }
    ]

    try:
        groq_start = time.time()
        response = client.chat.completions.create(
            model=VISION_MODEL,
            messages=messages,
            max_tokens=512,
            temperature=0.1,
            response_format={"type": "json_object"}
        )
        groq_elapsed_ms = (time.time() - groq_start) * 1000

        raw_text = (response.choices[0].message.content or "").strip()
        total_elapsed_ms = (time.time() - request_start) * 1000

        logger.info(
            f"✅ Groq responded in {groq_elapsed_ms:.0f}ms "
            f"(total {total_elapsed_ms:.0f}ms) | "
            f"model={VISION_MODEL}"
        )
        logger.info(f"📝 Raw model response: {raw_text[:300]}")

    except Exception as exc:
        total_elapsed_ms = (time.time() - request_start) * 1000
        logger.error(
            f"❌ Groq vision request failed after {total_elapsed_ms:.0f}ms | "
            f"model={VISION_MODEL} | error={exc}"
        )
        logger.error(traceback.format_exc())
        raise RuntimeError(
            f"Groq image analysis failed: {exc}"
        ) from exc

    try:
        parsed = _extract_json(raw_text)
        result = _validate_analysis_result(parsed)
    except Exception as parse_err:
        logger.error(f"❌ Failed to parse Groq response: {parse_err}")
        logger.error(f"Raw response was: {raw_text}")
        raise RuntimeError(
            f"Failed to parse Groq image analysis response: {parse_err}"
        ) from parse_err

    logger.info(
        f"✅ Analysis complete — "
        f"severity={result['severity']}, "
        f"ambulance_required={result['ambulance_required']}, "
        f"confidence={result['confidence']}"
    )
    return result


def first_aid_chat(user_query: str) -> str:
    """
    Provide first-aid advice using Groq
    (meta-llama/llama-4-scout-17b-16e-instruct).

    Parameters
    ----------
    user_query : str
        The user's question or emergency situation description.

    Returns
    -------
    str — First-aid advice and guidance.
    """
    logger.info(f"Using Groq model: {CHAT_MODEL}")
    logger.info(f"🚑 First-aid chat request: {user_query[:80]}...")

    request_start = time.time()
    client = _get_groq_client()

    system_prompt = (
        "You are SmartAid, an emergency first-aid assistant for the MediConnect platform.\n\n"
        "Rules:\n"
        "- Give short, clear answers in numbered steps.\n"
        "- Focus only on immediate first-aid actions.\n"
        "- Include a severity level: low, medium, or high.\n"
        "- If life-threatening, say to call emergency services immediately.\n"
        "- Respond in the same language as the user.\n"
        "- Avoid long explanations.\n"
        "- Keep response concise and actionable.\n\n"
        "Return format:\n"
        "Severity: <low|medium|high>\n"
        "Steps:\n"
        "1) ...\n"
        "2) ...\n"
        "Warnings: ..."
    )

    try:
        groq_start = time.time()
        message = client.chat.completions.create(
            model=CHAT_MODEL,
            max_tokens=512,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_query},
            ],
        )
        groq_elapsed_ms = (time.time() - groq_start) * 1000
        total_elapsed_ms = (time.time() - request_start) * 1000

        response_text = (message.choices[0].message.content or "").strip()
        logger.info(
            f"✅ First-aid response in {groq_elapsed_ms:.0f}ms "
            f"(total {total_elapsed_ms:.0f}ms) | model={CHAT_MODEL}"
        )
        return response_text

    except Exception as exc:
        logger.exception("First-aid chat failed")
        logger.error(traceback.format_exc())
        raise RuntimeError(f"First-aid chat failed: {exc}") from exc


def check_groq_connectivity() -> dict:
    """
    Test Groq API connectivity by listing available models for both chat and vision keys.

    Returns
    -------
    dict with connectivity results.
    """
    logger.info(f"Using Groq model: {VISION_MODEL}")
    chat_key = os.environ.get("GROQ_API_KEY", "").strip()
    vision_key = os.environ.get("GROQ_API_KEY_VISION", "").strip() or chat_key

    results = {}

    # Check chat/default key
    if not chat_key:
        results["chat"] = {"success": False, "connectivity": "no_api_key"}
    else:
        try:
            from groq import Groq
            client = Groq(api_key=chat_key)
            client.models.list()
            results["chat"] = {"success": True, "connectivity": "ok"}
        except Exception as exc:
            results["chat"] = {"success": False, "connectivity": f"error: {str(exc)}"}

    # Check vision key
    if not vision_key:
        results["vision"] = {"success": False, "connectivity": "no_api_key"}
    else:
        try:
            from groq import Groq
            client = Groq(api_key=vision_key)
            client.models.list()
            results["vision"] = {"success": True, "connectivity": "ok"}
        except Exception as exc:
            results["vision"] = {"success": False, "connectivity": f"error: {str(exc)}"}

    success = results["chat"]["success"] and results["vision"]["success"]
    return {
        "success": success,
        "provider": "groq",
        "chat_status": results["chat"],
        "vision_status": results["vision"],
        "model": VISION_MODEL,
        "connectivity": "ok" if success else "partial_or_no_connectivity"
    }


def analyze_accident_image_from_file(file_path: str) -> dict:
    """Convenience wrapper: reads a file from disk and analyses it."""
    import mimetypes
    mime, _ = mimetypes.guess_type(file_path)
    if mime is None:
        mime = "image/jpeg"
    with open(file_path, "rb") as f:
        return analyze_accident_image_with_groq(f.read(), mime_type=mime)
