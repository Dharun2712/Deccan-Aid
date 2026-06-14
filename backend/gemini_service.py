"""
Gemini AI Service Module — LifeLink / MediConnect
Provides:
  1. Accident Image Vision Analysis  (multimodal)
  2. First-Aid Chatbot               (text)
  3. Gemini connectivity health check
"""

import os
import pathlib
import json
import re
import io
import time
import logging
import traceback
from typing import Optional
from PIL import Image

# Load .env variables
from dotenv import load_dotenv
_env_path = pathlib.Path(__file__).resolve().parent / ".env"
load_dotenv(_env_path, override=False)

logger = logging.getLogger(__name__)

# Config
GEMINI_API_KEY = os.environ.get("GEMINI_API_KEY", "").strip() or os.environ.get("GOOGLE_API_KEY", "").strip()
GEMINI_MODEL = os.environ.get("GEMINI_MODEL", "gemini-1.5-flash").strip()

logger.info("=" * 50)
logger.info("GEMINI CONFIGURATION")
logger.info("=" * 50)
logger.info(f"GEMINI_API_KEY_PRESENT={bool(GEMINI_API_KEY)}")
if GEMINI_API_KEY:
    logger.info(f"GEMINI_API_KEY_PREFIX={GEMINI_API_KEY[:8]}****")
logger.info(f"GEMINI_MODEL={GEMINI_MODEL}")
logger.info("=" * 50)

if not GEMINI_API_KEY:
    logger.warning("⚠️ GEMINI_API_KEY not set. Gemini services will fail.")

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
    """Build and return a Gemini genai module configure, raising RuntimeError on failure."""
    if not GEMINI_API_KEY:
        logger.error("GEMINI_API_KEY is not set in os.environ.")
        raise RuntimeError("GEMINI_API_KEY is not set")
    try:
        import google.generativeai as genai
        genai.configure(api_key=GEMINI_API_KEY)
        return genai
    except ImportError:
        raise RuntimeError(
            "The 'google-generativeai' package is not installed. "
            "Install it with: pip install google-generativeai"
        )

def _extract_json(text: str) -> dict:
    """Extract JSON object from the response."""
    try:
        return json.loads(text.strip())
    except json.JSONDecodeError:
        pass

    md_match = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", text, re.DOTALL)
    if md_match:
        try:
            return json.loads(md_match.group(1))
        except json.JSONDecodeError:
            pass

    brace_match = re.search(r"\{.*\}", text, re.DOTALL)
    if brace_match:
        try:
            return json.loads(brace_match.group(0))
        except json.JSONDecodeError:
            pass

    raise ValueError(f"Could not extract JSON from model response: {text[:200]}")

def _validate_analysis_result(data: dict) -> dict:
    """Validate and normalize the result for front-end compatibility."""
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

    damage_map = {
        1: "very minor damage",
        2: "minor damage",
        3: "moderate damage",
        4: "severe damage",
        5: "catastrophic damage"
    }
    vehicle_damage_str = damage_map.get(damage_level, "unknown damage")

    result = {
        "people_detected": people_detected,
        "vehicles_detected": vehicles_detected,
        "possible_injured": possible_injured,
        "fire_detected": fire_detected,
        "damage_level": damage_level,
        "severity_level": severity_level,
        "ambulance_priority": ambulance_priority,
        
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
    """Resize image to optimize network transfer."""
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

def analyze_accident_image_with_gemini(image_bytes: bytes, mime_type: str = "image/jpeg") -> dict:
    """Analyze accident image via Gemini multimodal input."""
    logger.info(f"Using Gemini model: {GEMINI_MODEL}")
    logger.info(f"📸 Image analysis request — size={len(image_bytes)} bytes, type={mime_type}")

    request_start = time.time()
    genai = _get_gemini_client()

    compressed_bytes = _compress_image(image_bytes)
    
    try:
        # Load image via PIL for the SDK
        image = Image.open(io.BytesIO(compressed_bytes))
        
        # Configure model to force json output if compatible
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL,
            generation_config={"response_mime_type": "application/json"}
        )
        gemini_start = time.time()
        response = model.generate_content([ANALYSIS_PROMPT, image])
        gemini_elapsed_ms = (time.time() - gemini_start) * 1000
        total_elapsed_ms = (time.time() - request_start) * 1000

        raw_text = response.text.strip()
        logger.info(f"✅ Gemini responded in {gemini_elapsed_ms:.0f}ms (total {total_elapsed_ms:.0f}ms) | model={GEMINI_MODEL}")
        logger.info(f"📝 Raw model response: {raw_text[:300]}")

    except Exception as exc:
        total_elapsed_ms = (time.time() - request_start) * 1000
        logger.error(f"❌ Gemini vision request failed after {total_elapsed_ms:.0f}ms | model={GEMINI_MODEL} | error={exc}")
        logger.error(traceback.format_exc())
        raise RuntimeError(f"Gemini image analysis failed: {exc}") from exc

    try:
        parsed = _extract_json(raw_text)
        result = _validate_analysis_result(parsed)
    except Exception as parse_err:
        logger.error(f"❌ Failed to parse Gemini response: {parse_err}")
        logger.error(f"Raw response was: {raw_text}")
        raise RuntimeError(f"Failed to parse Gemini response: {parse_err}") from parse_err

    return result

def first_aid_chat(user_query: str) -> str:
    """Generate first-aid steps using Gemini Text model."""
    logger.info(f"Using Gemini model: {GEMINI_MODEL}")
    logger.info(f"🚑 First-aid chat request: {user_query[:80]}...")

    request_start = time.time()
    genai = _get_gemini_client()

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
        model = genai.GenerativeModel(
            model_name=GEMINI_MODEL,
            system_instruction=system_prompt
        )
        gemini_start = time.time()
        response = model.generate_content(user_query)
        gemini_elapsed_ms = (time.time() - gemini_start) * 1000
        total_elapsed_ms = (time.time() - request_start) * 1000

        response_text = response.text.strip()
        logger.info(f"✅ First-aid response in {gemini_elapsed_ms:.0f}ms (total {total_elapsed_ms:.0f}ms) | model={GEMINI_MODEL}")
        return response_text

    except Exception as exc:
        logger.exception("First-aid chat failed")
        logger.error(traceback.format_exc())
        raise RuntimeError(f"First-aid chat failed: {exc}") from exc

def check_gemini_connectivity() -> dict:
    """Test API connection to Gemini."""
    logger.info("Running Gemini connectivity check...")
    if not GEMINI_API_KEY:
        return {
            "success": False,
            "provider": "gemini",
            "connectivity": "no_api_key",
            "model": GEMINI_MODEL
        }
    try:
        genai = _get_gemini_client()
        genai.list_models()
        return {
            "success": True,
            "provider": "gemini",
            "connectivity": "ok",
            "model": GEMINI_MODEL
        }
    except Exception as exc:
        logger.error(f"Gemini health check error: {exc}")
        return {
            "success": False,
            "provider": "gemini",
            "connectivity": f"error: {str(exc)}",
            "model": GEMINI_MODEL
        }
