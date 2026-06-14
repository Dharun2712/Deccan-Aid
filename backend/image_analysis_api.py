"""
Accident Image Analysis API Router — LifeLink / MediConnect
Provides HTTP endpoints for uploading accident scene images and receiving
AI-powered severity analysis exclusively via Groq Vision.

No Gemini. No deprecated models. No fallback providers.

Endpoints:
  POST /api/accident-image/analyze       — Upload & analyse an image
  GET  /api/accident-image/images/{id}   — List S3 images for an accident
  GET  /api/accident-image/health        — Image-analysis service health
  GET  /api/groq/health                  — Groq connectivity health check
"""

import os
import logging
import time
import uuid
import traceback

from fastapi import APIRouter, HTTPException, UploadFile, File, Form
from fastapi.responses import JSONResponse
from typing import Optional

logger = logging.getLogger(__name__)

# ─────────────────────────────────────────────
# Model Constants  (resolved at import time)
# ─────────────────────────────────────────────
VISION_MODEL = os.getenv(
    "VISION_MODEL",
    "meta-llama/llama-4-scout-17b-16e-instruct",
)
CHAT_MODEL = os.getenv(
    "CHAT_MODEL",
    "meta-llama/llama-4-scout-17b-16e-instruct",
)

# ─────────────────────────────────────────────
# Router
# ─────────────────────────────────────────────
image_analysis_router = APIRouter(
    prefix="/api/accident-image",
    tags=["Accident Image Analysis"],
)

groq_health_router = APIRouter(
    prefix="/api/groq",
    tags=["Groq Health"],
)

# ─────────────────────────────────────────────
# File Validation
# ─────────────────────────────────────────────
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/jpg", "image/webp"}


# ─────────────────────────────────────────────
# POST /api/accident-image/analyze
# ─────────────────────────────────────────────
@image_analysis_router.post("/analyze")
async def analyze_accident(
    file: UploadFile = File(..., description="Accident scene image (JPEG/PNG/WebP)"),
    lat: Optional[float] = Form(None, description="Latitude of accident location"),
    lng: Optional[float] = Form(None, description="Longitude of accident location"),
):
    """
    🚑 Analyze an accident scene image using Groq Vision
    (meta-llama/llama-4-scout-17b-16e-instruct).

    Returns emergency-response-oriented assessment:
    - Severity (low / medium / high / critical)
    - Vehicle damage description
    - Visible injuries
    - Road condition
    - Ambulance required flag
    - Recommended response
    - Confidence score

    Supported formats: JPEG, PNG, WebP
    Max file size: 10 MB
    """
    start_time = time.time()

    # ── Validate content type ──────────────────────────────────────
    content_type = file.content_type or "image/jpeg"
    if content_type not in ALLOWED_MIME_TYPES:
        return JSONResponse(
            status_code=400,
            content={
                "success": False,
                "provider": "groq",
                "error": "unsupported_file_type",
                "message": (
                    f"Unsupported file type: {content_type}. "
                    f"Allowed: {', '.join(sorted(ALLOWED_MIME_TYPES))}"
                ),
            },
        )

    # ── Read bytes ─────────────────────────────────────────────────
    image_bytes = await file.read()
    image_size = len(image_bytes)

    if image_size > MAX_FILE_SIZE:
        return JSONResponse(
            status_code=400,
            content={
                "success": False,
                "provider": "groq",
                "error": "file_too_large",
                "message": (
                    f"File too large ({image_size} bytes). "
                    f"Maximum is {MAX_FILE_SIZE} bytes (10 MB)."
                ),
            },
        )

    if image_size == 0:
        return JSONResponse(
            status_code=400,
            content={
                "success": False,
                "provider": "groq",
                "error": "empty_file",
                "message": "Uploaded file is empty.",
            },
        )

    logger.info(
        f"Using Groq model: {VISION_MODEL}"
    )
    logger.info(
        f"📸 Received accident image: {file.filename} | "
        f"Size: {image_size} bytes | Type: {content_type}"
    )

    # ── Run Groq Vision Analysis ───────────────────────────────────
    try:
        from groq_service import analyze_accident_image_with_groq
        result = analyze_accident_image_with_groq(image_bytes, mime_type=content_type)
    except Exception as exc:
        elapsed_ms = (time.time() - start_time) * 1000
        logger.error(
            f"❌ Groq image analysis failed after {elapsed_ms:.0f}ms | "
            f"file={file.filename} | size={image_size} | type={content_type}"
        )
        logger.error(traceback.format_exc())
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "provider": "groq",
                "error": "model_error",
                "message": str(exc),
            },
        )

    elapsed_ms = (time.time() - start_time) * 1000

    # ── Build success response ─────────────────────────────────────
    response: dict = {
        "success": True,
        "provider": "groq",
        "analysis": result,
        "metadata": {
            "filename": file.filename,
            "file_size_bytes": image_size,
            "content_type": content_type,
            "model": VISION_MODEL,
            "processing_time_ms": round(elapsed_ms, 2),
        },
    }

    if lat is not None and lng is not None:
        response["location"] = {"lat": lat, "lng": lng}

    # ── S3 upload (non-fatal) ──────────────────────────────────────
    try:
        from aws_services import upload_accident_image
        accident_id = f"img-{uuid.uuid4().hex[:12]}"
        s3_result = upload_accident_image(accident_id, image_bytes, content_type)
        response["s3"] = s3_result
        logger.info(f"☁️  Image uploaded to S3: {s3_result['s3_key']}")
    except Exception as s3_err:
        logger.warning(f"⚠️  S3 upload failed (non-fatal): {s3_err}")
        response["s3"] = {"error": str(s3_err)}

    logger.info(
        f"✅ Analysis complete in {elapsed_ms:.0f}ms — "
        f"severity={result.get('severity')}, "
        f"ambulance_required={result.get('ambulance_required')}"
    )
    return response


# ─────────────────────────────────────────────
# GET /api/accident-image/images/{accident_id}
# ─────────────────────────────────────────────
@image_analysis_router.get("/images/{accident_id}")
async def get_accident_images(accident_id: str):
    """List all images stored in S3 for a given accident."""
    try:
        from aws_services import list_accident_images
        images = list_accident_images(accident_id)
        return {
            "success": True,
            "accident_id": accident_id,
            "images": images,
            "count": len(images),
        }
    except Exception as exc:
        logger.error(f"❌ Failed to list images: {exc}")
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "provider": "groq",
                "error": "s3_error",
                "message": str(exc),
            },
        )


# ─────────────────────────────────────────────
# GET /api/accident-image/health
# ─────────────────────────────────────────────
@image_analysis_router.get("/health")
async def image_analysis_health():
    """Health check for the image analysis service."""
    groq_available = bool(os.environ.get("GROQ_API_KEY", ""))
    status = "ready" if groq_available else "no_api_key"
    return {
        "success": True,
        "service": "accident-image-analysis",
        "provider": "groq",
        "status": status,
        "model": VISION_MODEL,
        "groq_api_key_present": groq_available,
        "max_file_size_mb": MAX_FILE_SIZE // (1024 * 1024),
        "supported_formats": sorted(ALLOWED_MIME_TYPES),
    }


# ─────────────────────────────────────────────
# GET /api/groq/health
# ─────────────────────────────────────────────
@groq_health_router.get("/health")
async def groq_health():
    """
    Groq API connectivity health check.

    Tests actual connectivity by calling client.models.list().

    Response:
    {
      "success": true,
      "provider": "groq",
      "api_key_present": true,
      "model": "meta-llama/llama-4-scout-17b-16e-instruct",
      "connectivity": "ok"
    }
    """
    logger.info(f"Using Groq model: {VISION_MODEL}")

    try:
        from groq_service import check_groq_connectivity
        result = check_groq_connectivity()
        status_code = 200 if result["success"] else 503
        return JSONResponse(status_code=status_code, content=result)
    except Exception as exc:
        logger.error(f"❌ Groq health check failed: {exc}")
        return JSONResponse(
            status_code=503,
            content={
                "success": False,
                "provider": "groq",
                "api_key_present": bool(os.environ.get("GROQ_API_KEY", "")),
                "model": VISION_MODEL,
                "connectivity": f"error: {str(exc)}",
            },
        )


# Export
__all__ = ["image_analysis_router", "groq_health_router"]
