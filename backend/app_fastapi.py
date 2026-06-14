"""
FastAPI Backend for Smart-Aid
Converted from Flask for better performance
MongoDB Atlas connection
"""

import os
import pathlib

# ── Load .env BEFORE anything else touches os.environ ──────────
from dotenv import load_dotenv

_env_path = pathlib.Path(__file__).resolve().parent / ".env"
load_dotenv(_env_path, override=True)

# Startup diagnostics (printed before logging is configured)
_chat_key = os.getenv("GROQ_API_KEY", "")
_vision_key = os.getenv("GROQ_API_KEY_VISION", "")
print(f"[startup] ENV FILE       : {_env_path}  (exists={_env_path.exists()})")
print(f"[startup] GROQ_API_KEY   : {'SET (' + _chat_key[:8] + '****)' if _chat_key else 'NOT SET'}")
print(f"[startup] GROQ_VISION_KEY: {'SET (' + _vision_key[:8] + '****)' if _vision_key else 'NOT SET'}")

import datetime
import bcrypt
import jwt
import time
from typing import Optional, List, Dict, Any
from fastapi import FastAPI, HTTPException, Depends, Header, WebSocket, WebSocketDisconnect, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel, EmailStr, Field
from pymongo import MongoClient, GEOSPHERE
from bson import ObjectId
import socketio
from contextlib import asynccontextmanager
import logging

# Groq SDK availability check
try:
    from groq import Groq as _GroqSDK
    _GROQ_SDK_AVAILABLE = True
except Exception as _groq_import_err:
    _GROQ_SDK_AVAILABLE = False
    logging.getLogger(__name__).warning(f"Groq SDK not available: {_groq_import_err}")

GROQ_AVAILABLE = _GROQ_SDK_AVAILABLE

# AWS DynamoDB + SNS integration
try:
    from aws_services import store_accident, publish_alert, get_accident as dynamo_get_accident, update_accident_status, upload_accident_image, list_accident_images
    AWS_ENABLED = True
except Exception as _aws_err:
    AWS_ENABLED = False
    logging.getLogger(__name__).warning(f"AWS services not available: {_aws_err}")

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%H:%M:%S'
)
logger = logging.getLogger(__name__)

# CloudWatch Logs integration
try:
    import watchtower
    import boto3
    cw_handler = watchtower.CloudWatchLogHandler(
        log_group_name="/lifelink/backend",
        log_stream_name="ec2-fastapi",
        boto3_client=boto3.client("logs", region_name=os.environ.get("AWS_REGION", "us-east-1")),
    )
    cw_handler.setFormatter(logging.Formatter('%(asctime)s - %(levelname)s - %(message)s'))
    logging.getLogger().addHandler(cw_handler)
    logger.info("☁️ CloudWatch Logs connected: /lifelink/backend")
except Exception as _cw_err:
    logger.warning(f"CloudWatch Logs not available: {_cw_err}")

# ---------- Configuration ----------
MONGODB_URI = (
    os.environ.get("MONGODB_URI")
    or os.environ.get("MONGO_URI")
    or "mongodb+srv://Dharun:Dharun2712@cluster0.yr5quzl.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0"
)
# The production/testing DB in your cluster is named "smart_ambulance".
# Use that DB so existing driver and user documents are found.
DB_NAME = os.environ.get("DB_NAME", "smart_ambulance")
JWT_SECRET = os.environ.get("JWT_SECRET", "your_secret_key_here_change_in_production")
JWT_ALGORITHM = os.environ.get("JWT_ALGORITHM", "HS256")
GROQ_API_KEY = os.environ.get("GROQ_API_KEY", "")
GROQ_API_KEY_VISION = os.environ.get("GROQ_API_KEY_VISION", "")
VISION_MODEL = os.getenv("VISION_MODEL", "meta-llama/llama-4-scout-17b-16e-instruct")
CHAT_MODEL = os.getenv("CHAT_MODEL", "meta-llama/llama-4-scout-17b-16e-instruct")
MONGO_TLS_ALLOW_INVALID_CERTIFICATES = (
    os.environ.get("MONGO_TLS_ALLOW_INVALID_CERTIFICATES", "true").lower()
    in ("1", "true", "yes")
)

# ---------- MongoDB Setup ----------
mongo_client = MongoClient(
    MONGODB_URI,
    serverSelectionTimeoutMS=5000,
    connectTimeoutMS=10000,
    socketTimeoutMS=10000,
    retryWrites=True,
    w='majority',
    maxPoolSize=50,  # Increased connection pool for better performance
    minPoolSize=10,
    maxIdleTimeMS=45000,
    tlsAllowInvalidCertificates=MONGO_TLS_ALLOW_INVALID_CERTIFICATES
)
db = mongo_client[DB_NAME]

# Collections
users = db.users
patient_requests = db.patient_requests
ambulance_drivers = db.ambulance_drivers
hospitals = db.hospitals

# Create indexes
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Create indexes
    # ── Groq startup diagnostics ───────────────────────────────────
    logger.info("=" * 50)
    logger.info("GROQ CONFIGURATION")
    logger.info("=" * 50)
    logger.info(f"GROQ_API_KEY_PRESENT={bool(os.getenv('GROQ_API_KEY'))}")
    logger.info(f"GROQ_API_KEY_VISION_PRESENT={bool(os.getenv('GROQ_API_KEY_VISION'))}")
    logger.info(f"VISION_MODEL={VISION_MODEL}")
    logger.info(f"CHAT_MODEL={CHAT_MODEL}")
    logger.info("=" * 50)

    try:
        # Test connection first
        mongo_client.admin.command('ping')
        logger.info("MongoDB connection successful")

        # Create indexes
        patient_requests.create_index([("location", GEOSPHERE)])
        ambulance_drivers.create_index([("location", GEOSPHERE)])
        hospitals.create_index([("location", GEOSPHERE)])

        # Performance indexes for faster queries
        users.create_index([("email", 1), ("role", 1)])  # Fast email+role lookup
        users.create_index([("phone", 1), ("role", 1)])  # Fast phone+role lookup
        users.create_index([("hospital_code", 1), ("role", 1)])  # Fast hospital admin lookup
        ambulance_drivers.create_index([("driver_id", 1)])  # Fast driver_id lookup
        ambulance_drivers.create_index([("status", 1)])  # Fast driver status filtering
        patient_requests.create_index([("status", 1)])  # Fast request status filtering
        patient_requests.create_index([("user_id", 1)])  # Fast user request history

        logger.info("MongoDB indexes created successfully")
        
        # Initialize hospitals if not already present
        hospital_count = hospitals.count_documents({})
        if hospital_count == 0:
            logger.info("No hospitals found. Initializing hospitals...")
            try:
                from init_kongu_hospitals import init_kongu_hospitals
                init_kongu_hospitals()
                logger.info("Hospitals initialized successfully")
            except Exception as init_error:
                logger.warning(f"Hospital initialization error: {init_error}")
        else:
            logger.info(f"Found {hospital_count} hospitals in database")
    except Exception as e:
        logger.warning(f"MongoDB connection/index error: {e}")
        logger.warning("Backend will start but database operations may fail")
    
    yield
    
    # Shutdown
    try:
        mongo_client.close()
        logger.info("MongoDB connection closed")
    except Exception as e:
        logger.warning(f"Error closing MongoDB connection: {e}")

# ---------- FastAPI App ----------
app = FastAPI(
    title="Smart-Aid API",
    description="Emergency ambulance service API",
    version="2.0.0",
    lifespan=lifespan
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class FirstAidChatRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=800)


class FirstAidChatResponse(BaseModel):
    response: str


def _build_first_aid_prompt(user_input: str) -> str:
    return (
        "You are SmartAid, an emergency first-aid assistant.\n"
        "Rules:\n"
        "- Give short, clear answers in numbered steps.\n"
        "- Focus only on immediate first-aid actions.\n"
        "- Include a severity level: low, medium, or high.\n"
        "- If life-threatening, say to call emergency services immediately.\n"
        "- Respond in the same language as the user.\n"
        "- Avoid long explanations.\n\n"
        "Return format:\n"
        "Severity: <low|medium|high>\n"
        "Steps:\n"
        "1) ...\n"
        "2) ...\n"
        "Warnings: ...\n\n"
        f"User: {user_input}\n"
    )


@app.post("/api/first-aid/chat", response_model=FirstAidChatResponse)
async def first_aid_chat(payload: FirstAidChatRequest):
    """First-aid chatbot powered exclusively by Groq (meta-llama/llama-4-scout-17b-16e-instruct)."""
    if not GROQ_AVAILABLE:
        return JSONResponse(
            status_code=503,
            content={
                "success": False,
                "provider": "groq",
                "error": "sdk_unavailable",
                "message": "Groq SDK is not installed. Run: pip install groq",
            },
        )
    if not GROQ_API_KEY:
        return JSONResponse(
            status_code=503,
            content={
                "success": False,
                "provider": "groq",
                "error": "no_api_key",
                "message": "GROQ_API_KEY is not configured.",
            },
        )

    try:
        from groq_service import first_aid_chat as groq_first_aid
        logger.info(f"🚑 Using Groq model: {CHAT_MODEL} for first-aid chat")
        text = groq_first_aid(payload.query)
        if not text:
            return JSONResponse(
                status_code=500,
                content={
                    "success": False,
                    "provider": "groq",
                    "error": "empty_response",
                    "message": "Groq returned an empty response.",
                },
            )
        return FirstAidChatResponse(response=text)
    except Exception as exc:
        logger.error(f"❌ Groq first-aid chat error: {exc}", exc_info=True)
        return JSONResponse(
            status_code=500,
            content={
                "success": False,
                "provider": "groq",
                "error": "model_error",
                "message": str(exc),
            },
        )

# Import and include Risk Prediction API Router
try:
    from risk_api import risk_router
    app.include_router(risk_router)
    logger.info("✅ Risk Prediction API loaded successfully")
except Exception as e:
    logger.warning(f"⚠️  Risk Prediction API not loaded: {e}")

# Import and include Accident Image Analysis Router + Groq Health Router
try:
    from image_analysis_api import image_analysis_router, groq_health_router
    app.include_router(image_analysis_router)
    app.include_router(groq_health_router)
    logger.info("✅ Accident Image Analysis API loaded successfully")
    logger.info("✅ Groq Health endpoint loaded: GET /api/groq/health")
except Exception as e:
    logger.warning(f"⚠️  Accident Image Analysis API not loaded: {e}")

# Import and include Ambulance Routing Router
try:
    from routing_api import routing_router
    app.include_router(routing_router)
    logger.info("✅ Ambulance Routing API loaded successfully")
except Exception as e:
    logger.warning(f"⚠️  Ambulance Routing API not loaded: {e}")

# Request Logging Middleware
@app.middleware("http")
async def log_requests(request: Request, call_next):
    start_time = time.time()
    
    # Get client IP
    client_ip = request.client.host if request.client else "unknown"
    
    # Process request
    response = await call_next(request)
    
    # Calculate duration
    duration = (time.time() - start_time) * 1000  # Convert to milliseconds
    
    # Log with status code flag
    status_flag = "OK" if response.status_code < 400 else "ERR"
    logger.info(
        f"{status_flag} {request.method:6} {request.url.path:40} | "
        f"Status: {response.status_code} | "
        f"Duration: {duration:.2f}ms | "
        f"Client: {client_ip}"
    )
    
    return response

# ---------- Socket.IO Setup ----------
sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins="*",
    logger=True,
    engineio_logger=False,
    ping_timeout=60,
    ping_interval=25,
    max_http_buffer_size=1000000,
    always_connect=True
)

# Mount Socket.IO
socket_app = socketio.ASGIApp(
    sio, 
    other_asgi_app=app, 
    socketio_path="socket.io"
)

# ---------- Helper Functions ----------
def str_to_objectid(id_str: str) -> ObjectId:
    """Convert string to MongoDB ObjectId"""
    try:
        return ObjectId(id_str)
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid ID format")

def hash_password(password: str) -> bytes:
    """Hash password using bcrypt"""
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())

def verify_password(password: str, hashed: bytes) -> bool:
    """Verify password against hash"""
    try:
        return bcrypt.checkpw(password.encode('utf-8'), hashed)
    except Exception:
        return False

def create_jwt_token(user_id: ObjectId, role: str) -> str:
    """Create JWT token"""
    payload = {
        "sub": str(user_id),
        "role": role,
        "exp": datetime.datetime.utcnow() + datetime.timedelta(days=30),
        "iat": datetime.datetime.utcnow()
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)

def decode_jwt_token(token: str) -> Dict[str, Any]:
    """Decode and verify JWT token"""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")

async def get_current_user(authorization: str = Header(None)) -> Dict[str, Any]:
    """Dependency to get current authenticated user"""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")
    
    token = authorization.replace("Bearer ", "")
    payload = decode_jwt_token(token)
    
    user = users.find_one({"_id": str_to_objectid(payload["sub"])})
    if not user:
        raise HTTPException(status_code=401, detail="User not found")
    
    user["_id"] = str(user["_id"])
    return user

import math

def calculate_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Calculate distance in km using Haversine formula"""
    R = 6371.0  # Earth's radius in km
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2)**2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2)**2
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    return round(R * c, 2)

def calculate_eta(distance_km: float) -> int:
    """Calculate ETA in minutes based on average traffic speed (40 km/h)"""
    if distance_km < 0.1:
        return 0
    return max(1, int(2 + (distance_km / 40.0) * 60.0))

def serialize_doc(doc: Dict) -> Dict:
    """Serialize MongoDB document for JSON response"""
    if doc is None:
        return None
    if isinstance(doc, list):
        return [serialize_doc(d) for d in doc]
    if "_id" in doc:
        doc["_id"] = str(doc["_id"])
    for key, value in doc.items():
        if isinstance(value, ObjectId):
            doc[key] = str(value)
        elif isinstance(value, datetime.datetime):
            doc[key] = value.isoformat()
    return doc

# ---------- Pydantic Models ----------
class RegisterClientRequest(BaseModel):
    name: str
    identifier: str  # email or phone
    password: str = Field(min_length=6)
    blood_group: Optional[str] = None
    has_medical_allergies: Optional[bool] = False

class RegisterDriverRequest(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str = Field(min_length=6)
    driver_id: str
    vehicle_type: str
    vehicle_plate: str
    vehicle_model: str
    license_number: str

class RegisterHospitalRequest(BaseModel):
    hospital_name: str
    hospital_code: str
    password: str = Field(min_length=6)
    address: str
    phone: str
    email: EmailStr

class LoginClientRequest(BaseModel):
    identifier: str  # email or phone
    password: str

class LoginDriverRequest(BaseModel):
    driver_id: str
    password: str

class LoginAdminRequest(BaseModel):
    hospital_code: str
    password: str

class SOSRequest(BaseModel):
    location: Dict[str, float]  # {"lat": float, "lng": float}
    condition: Optional[str] = "other"
    preliminary_severity: Optional[str] = "unknown"
    sensor_data: Optional[Dict] = {}
    auto_triggered: Optional[bool] = False
    contact: Optional[str] = ""
    image_base64: Optional[str] = None  # Base64-encoded accident image
    accident_analysis: Optional[Dict] = None  # AI image analysis results

class AcceptRequestRequest(BaseModel):
    request_id: str

class InjuryAssessmentRequest(BaseModel):
    request_id: str
    injury_risk: str
    injury_notes: str

class UpdateLocationRequest(BaseModel):
    location: Dict[str, float]  # {"lat": float, "lng": float}

class ConfirmAdmissionRequest(BaseModel):
    request_id: str
    action: str  # "accept" or "reject"

class UpdateCapacityRequest(BaseModel):
    capacity: Dict[str, int]

# ---------- Ambulance Dispatch Decision Engine ----------
class DispatchRequest(BaseModel):
    """Input for ambulance dispatch decision"""
    number_of_people_detected: Optional[int] = 0
    number_of_vehicles_involved: Optional[int] = 0
    estimated_injured_people: Optional[int] = 0
    fire_or_smoke_detected: Optional[bool] = False
    vehicle_damage_level: Optional[int] = 1  # 1–5
    manual_sos_triggered: Optional[bool] = False
    reported_risk_level: Optional[str] = "MEDIUM"  # LOW | MEDIUM | HIGH

def determine_ambulance_dispatch(data: dict) -> dict:
    """
    Core dispatch decision logic.
    Returns severity_level, ambulance_level, ambulance_type, dispatch_reason, priority.
    """
    manual = data.get("manual_sos_triggered", False)
    risk = (data.get("reported_risk_level") or "MEDIUM").upper()
    damage = data.get("vehicle_damage_level", 1) or 1
    injured = data.get("estimated_injured_people", 0) or 0
    fire = data.get("fire_or_smoke_detected", False)
    vehicles = data.get("number_of_vehicles_involved", 0) or 0

    # --- Manual SOS path ---
    if manual:
        if risk == "HIGH":
            return {
                "severity_level": "CRITICAL",
                "ambulance_level": "LEVEL_3_ICU",
                "ambulance_type": "ICU",
                "dispatch_reason": "Manual SOS with HIGH risk level reported by user",
                "priority": "HIGH",
            }
        elif risk == "LOW":
            return {
                "severity_level": "LOW",
                "ambulance_level": "LEVEL_1_BLS",
                "ambulance_type": "BLS",
                "dispatch_reason": "Manual SOS with LOW risk — basic life support sufficient",
                "priority": "LOW",
            }
        else:
            return {
                "severity_level": "MEDIUM",
                "ambulance_level": "LEVEL_2_ALS",
                "ambulance_type": "ALS",
                "dispatch_reason": "Manual SOS with MEDIUM risk — advanced life support needed",
                "priority": "MEDIUM",
            }

    # --- AI / sensor accident analysis path ---
    # Level 3 – ICU
    if damage >= 3 and injured >= 3 and fire:
        return {
            "severity_level": "CRITICAL",
            "ambulance_level": "LEVEL_3_ICU",
            "ambulance_type": "ICU",
            "dispatch_reason": f"Major accident: damage level {damage}/5, {injured} injured, fire/smoke detected",
            "priority": "HIGH",
        }
    # Still Level 3 for very high damage even without fire
    if damage >= 4 and injured >= 3:
        return {
            "severity_level": "CRITICAL",
            "ambulance_level": "LEVEL_3_ICU",
            "ambulance_type": "ICU",
            "dispatch_reason": f"Severe collision: damage level {damage}/5, {injured} injured, multiple trauma likely",
            "priority": "HIGH",
        }

    # Level 2 – ALS
    if damage >= 2 and injured >= 2 and vehicles >= 2:
        return {
            "severity_level": "MEDIUM",
            "ambulance_level": "LEVEL_2_ALS",
            "ambulance_type": "ALS",
            "dispatch_reason": f"Multi-vehicle incident: {vehicles} vehicles, {injured} injured, damage level {damage}/5",
            "priority": "MEDIUM",
        }
    if damage >= 2 and injured >= 2:
        return {
            "severity_level": "MEDIUM",
            "ambulance_level": "LEVEL_2_ALS",
            "ambulance_type": "ALS",
            "dispatch_reason": f"Moderate accident: damage level {damage}/5, {injured} injured",
            "priority": "MEDIUM",
        }
    if fire:
        return {
            "severity_level": "MEDIUM",
            "ambulance_level": "LEVEL_2_ALS",
            "ambulance_type": "ALS",
            "dispatch_reason": "Fire/smoke detected — advanced life support dispatched as precaution",
            "priority": "MEDIUM",
        }

    # Level 1 – BLS (default)
    return {
        "severity_level": "LOW",
        "ambulance_level": "LEVEL_1_BLS",
        "ambulance_type": "BLS",
        "dispatch_reason": f"Minor incident: damage level {damage}/5, {injured} injured, no fire",
        "priority": "LOW",
    }

@app.post("/api/dispatch/decide")
async def dispatch_decide(payload: DispatchRequest):
    """
    Standalone endpoint: given accident parameters, returns the recommended
    ambulance type (BLS / ALS / ICU) and priority.
    """
    result = determine_ambulance_dispatch(payload.dict())
    return result

@app.get("/api/dispatch/levels")
async def dispatch_levels():
    """Return available ambulance dispatch levels for reference"""
    return {
        "levels": [
            {"level": "LEVEL_1_BLS", "type": "BLS", "name": "Basic Life Support", "description": "Minor injuries or low-risk incidents"},
            {"level": "LEVEL_2_ALS", "type": "ALS", "name": "Advanced Life Support", "description": "Serious injuries requiring advanced medical care"},
            {"level": "LEVEL_3_ICU", "type": "ICU", "name": "Critical Care Ambulance", "description": "Life-threatening situations or severe accidents"},
        ]
    }

# ESP32 Accident Detection Models
class ESP32AccidentData(BaseModel):
    device_id: str
    event: str  # "ACCIDENT", "IMPACT", "ROLLOVER", etc.
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    impact_force: Optional[float] = None
    temperature: Optional[float] = None  # LM35 temperature sensor reading in Celsius
    timestamp: Optional[str] = None
    battery_level: Optional[int] = None
    additional_data: Optional[Dict] = {}

# Device API Key for ESP32 authentication
ESP32_DEVICE_KEY = "smartaid-prototype"

# ---------- ESP32 Accident Webhook Endpoints ----------
@app.post("/api/accident")
async def accident_webhook(
    data: ESP32AccidentData,
    x_device_key: str = Header(None)
):
    """
    Webhook endpoint for ESP32 accident detection.
    ESP32 sends POST request here when accident is detected.
    
    Required Header: X-DEVICE-KEY: smartaid-prototype
    """
    # Validate device key
    if x_device_key != ESP32_DEVICE_KEY:
        logger.warning(f"Unauthorized accident webhook attempt from device: {data.device_id}")
        raise HTTPException(status_code=401, detail="Invalid device key")
    
    logger.info(f"🚨 ACCIDENT DETECTED from device: {data.device_id}, event: {data.event}")
    
    try:
        # Create accident record in database
        accident_record = {
            "device_id": data.device_id,
            "event": data.event,
            "location": {
                "type": "Point",
                "coordinates": [data.longitude or 0, data.latitude or 0]
            },
            "latitude": data.latitude,
            "longitude": data.longitude,
            "impact_force": data.impact_force,
            "temperature": data.temperature,  # LM35 sensor reading
            "battery_level": data.battery_level,
            "additional_data": data.additional_data,
            "timestamp": datetime.datetime.utcnow(),
            "device_timestamp": data.timestamp,
            "status": "detected",
            "processed": False
        }
        
        # Store in MongoDB accidents collection
        accidents_collection = db.accidents
        result = accidents_collection.insert_one(accident_record)
        accident_id = str(result.inserted_id)
        
        logger.info(f"✅ Accident recorded in MongoDB with ID: {accident_id}")
        
        # Also store in AWS DynamoDB + send SNS alert
        if AWS_ENABLED:
            try:
                dynamo_record = store_accident(
                    vehicle_id=data.device_id,
                    latitude=data.latitude or 0,
                    longitude=data.longitude or 0,
                    impact_force=data.impact_force or 0,
                    status="detected",
                )
                logger.info(f"✅ Accident stored in DynamoDB: {dynamo_record['accident_id']}")
                
                if data.latitude and data.longitude:
                    sns_msg_id = publish_alert(data.latitude, data.longitude, accident_id, impact_force=data.impact_force or 0, device_id=data.device_id or '')
                    logger.info(f"✅ SNS alert sent: {sns_msg_id}")
            except Exception as aws_err:
                logger.warning(f"AWS integration error (non-fatal): {aws_err}")
        
        # If location is available, auto-create SOS request
        if data.latitude and data.longitude:
            # Create auto-triggered SOS request with all fields driver dashboard expects
            sos_request = {
                "user_id": None,  # ESP32 device, no user
                "client_id": None,  # No client for auto-triggered
                "device_id": data.device_id,
                "name": f"🚨 AUTO-ACCIDENT {data.device_id[-6:]}",
                "phone": "AUTO-DETECTED",
                "location": {
                    "type": "Point",
                    "coordinates": [data.longitude, data.latitude]
                },
                "condition": "Vehicle Accident (Auto-Detected)",
                "severity": "critical" if data.impact_force and data.impact_force > 5 else "high",
                "preliminary_severity": "critical" if data.impact_force and data.impact_force > 5 else "high",
                "auto_triggered": True,
                "sensor_data": {
                    "impact_force": data.impact_force,
                    "temperature": data.temperature,  # LM35 sensor reading
                    "event_type": data.event,
                    "battery_level": data.battery_level
                },
                "status": "pending",
                "timestamp": datetime.datetime.utcnow(),
                "created_at": datetime.datetime.utcnow(),
                "accident_id": accident_id
            }
            
            sos_result = patient_requests.insert_one(sos_request)
            sos_id = str(sos_result.inserted_id)
            
            # Compute ambulance dispatch for ESP32 accident
            esp_dispatch = determine_ambulance_dispatch({
                "vehicle_damage_level": min(5, int((data.impact_force or 3) * 1.0)),
                "estimated_injured_people": 1,
                "fire_or_smoke_detected": (data.temperature or 0) > 60,
                "number_of_vehicles_involved": 1,
                "manual_sos_triggered": False,
            })
            patient_requests.update_one(
                {"_id": sos_result.inserted_id},
                {"$set": {"ambulance_dispatch": esp_dispatch}}
            )
            logger.info(f"🚑 ESP32 dispatch: {esp_dispatch['ambulance_type']} ({esp_dispatch['priority']})")
            
            logger.info(f"🆘 Auto-SOS created with ID: {sos_id}")
            
            # Emit Socket.IO events to notify drivers
            try:
                # Event data for drivers
                event_data = {
                    "_id": sos_id,
                    "request_id": sos_id,
                    "accident_id": accident_id,
                    "device_id": data.device_id,
                    "name": f"🚨 AUTO-ACCIDENT {data.device_id[-6:]}",
                    "condition": "Vehicle Accident (Auto-Detected)",
                    "severity": "critical" if data.impact_force and data.impact_force > 5 else "high",
                    "location": {
                        "type": "Point",
                        "coordinates": [data.longitude, data.latitude]
                    },
                    "latitude": data.latitude,
                    "longitude": data.longitude,
                    "auto_triggered": True,
                    "status": "pending",
                    "ambulance_dispatch": esp_dispatch
                }
                
                # Emit to drivers room - use the event name driver is listening for
                await sio.emit("new_sos_request", event_data, room="drivers")
                logger.info("📡 Socket.IO 'new_sos_request' emitted to drivers room")
                
                # Also emit broadcast for any connected clients
                await sio.emit("sos_alert", event_data)
                logger.info("📡 Socket.IO 'sos_alert' broadcast emitted")
                
            except Exception as e:
                logger.warning(f"Socket.IO emit failed: {e}")
            
            return {
                "status": "received",
                "accident_id": accident_id,
                "sos_id": sos_id,
                "message": "Accident detected and SOS dispatched",
                "auto_sos": True
            }
        
        return {
            "status": "received",
            "accident_id": accident_id,
            "message": "Accident recorded (no location for auto-SOS)",
            "auto_sos": False
        }
        
    except Exception as e:
        logger.error(f"Error processing accident webhook: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/accidents")
async def get_accidents(limit: int = 50):
    """Get recent accident records"""
    try:
        accidents_collection = db.accidents
        accidents = list(accidents_collection.find().sort("timestamp", -1).limit(limit))
        return {"accidents": [serialize_doc(a) for a in accidents]}
    except Exception as e:
        logger.error(f"Error fetching accidents: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/accidents/{accident_id}")
async def get_accident(accident_id: str):
    """Get specific accident by ID"""
    try:
        accidents_collection = db.accidents
        accident = accidents_collection.find_one({"_id": str_to_objectid(accident_id)})
        if not accident:
            raise HTTPException(status_code=404, detail="Accident not found")
        return serialize_doc(accident)
    except Exception as e:
        logger.error(f"Error fetching accident: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ---------- Authentication Endpoints ----------
@app.post("/api/register/client")
async def register_client(payload: RegisterClientRequest):
    """Register a new client"""
    identifier = payload.identifier.strip()
    is_email = "@" in identifier
    
    # Check if user already exists
    if is_email:
        existing = users.find_one({"email": identifier.lower(), "role": "client"})
        if existing:
            raise HTTPException(status_code=409, detail="Email already registered")
    else:
        existing = users.find_one({"phone": identifier, "role": "client"})
        if existing:
            raise HTTPException(status_code=409, detail="Phone number already registered")
    
    # Create user document
    user_doc = {
        "role": "client",
        "name": payload.name.strip(),
        "password": hash_password(payload.password),
        "verified": False,
        "google_auth": False,
        "created_at": datetime.datetime.utcnow()
    }
    
    # Add email or phone
    if is_email:
        user_doc["email"] = identifier.lower()
    else:
        user_doc["phone"] = identifier
    
    # Add medical information
    if payload.blood_group:
        user_doc["blood_group"] = payload.blood_group
    if payload.has_medical_allergies is not None:
        user_doc["has_medical_allergies"] = bool(payload.has_medical_allergies)
    
    # Insert user
    result = users.insert_one(user_doc)
    token = create_jwt_token(result.inserted_id, "client")
    
    return {
        "success": True,
        "role": "client",
        "user_id": str(result.inserted_id),
        "token": token
    }

@app.post("/api/register/driver")
async def register_driver(payload: RegisterDriverRequest):
    """Register a new driver"""
    # Check duplicates
    if users.find_one({"email": payload.email.lower()}):
        raise HTTPException(status_code=409, detail="Email already registered")
    if users.find_one({"phone": payload.phone}):
        raise HTTPException(status_code=409, detail="Phone already registered")
    if users.find_one({"driver_id": payload.driver_id}):
        raise HTTPException(status_code=409, detail="Driver ID already taken")
    
    # Create user
    user_doc = {
        "role": "driver",
        "name": payload.name.strip(),
        "email": payload.email.lower(),
        "phone": payload.phone,
        "password": hash_password(payload.password),
        "created_at": datetime.datetime.utcnow()
    }
    user_result = users.insert_one(user_doc)
    
    # Create driver profile
    driver_doc = {
        "user_id": user_result.inserted_id,
        "driver_id": payload.driver_id,
        "name": payload.name,
        "email": payload.email.lower(),
        "phone": payload.phone,
        "vehicle_type": payload.vehicle_type,
        "vehicle_plate": payload.vehicle_plate,
        "vehicle_model": payload.vehicle_model,
        "license_number": payload.license_number,
        "status": "available",
        "active": True,
        "location": None,
        "created_at": datetime.datetime.utcnow()
    }
    ambulance_drivers.insert_one(driver_doc)
    
    token = create_jwt_token(user_result.inserted_id, "driver")
    
    return {
        "success": True,
        "role": "driver",
        "user_id": str(user_result.inserted_id),
        "token": token
    }

@app.post("/api/register/hospital")
async def register_hospital(payload: RegisterHospitalRequest):
    """Register a new hospital"""
    # Check duplicates
    if users.find_one({"email": payload.email.lower(), "role": "admin"}):
        raise HTTPException(status_code=409, detail="Email already registered")
    if hospitals.find_one({"hospital_code": payload.hospital_code}):
        raise HTTPException(status_code=409, detail="Hospital code already exists")
    
    # Create user
    user_doc = {
        "role": "admin",
        "name": payload.hospital_name,
        "email": payload.email.lower(),
        "phone": payload.phone,
        "password": hash_password(payload.password),
        "hospital_code": payload.hospital_code,
        "created_at": datetime.datetime.utcnow()
    }
    user_result = users.insert_one(user_doc)
    
    # Create hospital profile
    hospital_doc = {
        "user_id": user_result.inserted_id,
        "hospital_name": payload.hospital_name,
        "hospital_code": payload.hospital_code,
        "address": payload.address,
        "phone": payload.phone,
        "email": payload.email.lower(),
        "capacity": {
            "icu_beds": 0,
            "general_beds": 0,
            "doctors_available": 0
        },
        "location": None,
        "active": True,
        "created_at": datetime.datetime.utcnow()
    }
    hospitals.insert_one(hospital_doc)
    
    token = create_jwt_token(user_result.inserted_id, "admin")
    
    return {
        "success": True,
        "role": "admin",
        "user_id": str(user_result.inserted_id),
        "token": token
    }

@app.post("/api/login/client")
async def login_client(payload: LoginClientRequest):
    """Client login - optimized with indexes"""
    identifier = payload.identifier.strip()
    is_email = "@" in identifier
    
    # Use indexed queries for faster lookup
    if is_email:
        user = users.find_one(
            {"email": identifier.lower(), "role": "client"},
            projection={"_id": 1, "password": 1, "role": 1}  # Only fetch needed fields
        )
    else:
        user = users.find_one(
            {"phone": identifier, "role": "client"},
            projection={"_id": 1, "password": 1, "role": 1}
        )
    
    if not user or not verify_password(payload.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_jwt_token(user["_id"], "client")
    
    return {
        "success": True,
        "token": token,
        "role": "client",
        "user_id": str(user["_id"])
    }

@app.post("/api/login/driver")
async def login_driver(payload: LoginDriverRequest):
    """Driver login - optimized with indexes"""
    # Use indexed query for faster lookup
    driver = ambulance_drivers.find_one(
        {"driver_id": payload.driver_id},
        projection={"_id": 1, "user_id": 1}
    )
    if not driver:
        raise HTTPException(status_code=401, detail="Driver not found")
    
    user = users.find_one(
        {"_id": driver["user_id"]},
        projection={"_id": 1, "password": 1, "role": 1}
    )
    if not user or not verify_password(payload.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_jwt_token(user["_id"], "driver")
    
    return {
        "success": True,
        "token": token,
        "role": "driver",
        "user_id": str(user["_id"])
    }

@app.post("/api/login/admin")
async def login_admin(payload: LoginAdminRequest):
    """Hospital admin login - optimized with indexes"""
    # Use indexed query for faster lookup
    user = users.find_one(
        {"hospital_code": payload.hospital_code, "role": "admin"},
        projection={"_id": 1, "password": 1, "role": 1}
    )
    if not user or not verify_password(payload.password, user["password"]):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    token = create_jwt_token(user["_id"], "admin")
    
    return {
        "success": True,
        "token": token,
        "role": "admin",
        "user_id": str(user["_id"])
    }

# ---------- Client Endpoints ----------
@app.post("/api/client/sos")
async def trigger_sos(payload: SOSRequest, current_user: Dict = Depends(get_current_user)):
    """Trigger SOS request"""
    if current_user.get("role") != "client":
        raise HTTPException(status_code=403, detail="Only clients can trigger SOS")
    
    location = payload.location
    if not location or "lat" not in location or "lng" not in location:
        raise HTTPException(status_code=400, detail="Location (lat, lng) is required")
    
    # Get user info
    user_name = current_user.get("name", "Unknown")
    user_contact = payload.contact or current_user.get("phone", "")
    blood_group = current_user.get("blood_group")
    has_medical_allergies = current_user.get("has_medical_allergies", False)
    
    # Create SOS request
    sos_doc = {
        "client_id": str_to_objectid(current_user["_id"]),
        "user_name": user_name,
        "user_contact": user_contact,
        "blood_group": blood_group,
        "has_medical_allergies": has_medical_allergies,
        "driver_id": None,
        "hospital_id": None,
        "location": {
            "type": "Point",
            "coordinates": [location["lng"], location["lat"]]
        },
        "condition": payload.condition,
        "preliminary_severity": payload.preliminary_severity,
        "injury_level": None,
        "status": "pending",
        "auto_triggered": payload.auto_triggered,
        "sensor_data": payload.sensor_data,
        "vitals": {},
        "picked_up_at": None,
        "accepted_at": None,
        "assigned_at": None,
        "timestamp": datetime.datetime.utcnow()
    }
    
    # Store accident image if provided
    if payload.image_base64:
        sos_doc["image_base64"] = payload.image_base64
    
    # Store AI accident analysis if provided
    if payload.accident_analysis:
        sos_doc["accident_analysis"] = payload.accident_analysis
    
    # --- Auto-compute ambulance dispatch recommendation ---
    dispatch_input = {}
    if payload.accident_analysis:
        aa = payload.accident_analysis
        dispatch_input = {
            "number_of_people_detected": aa.get("people_detected", 0),
            "number_of_vehicles_involved": aa.get("vehicles_detected", 0),
            "estimated_injured_people": aa.get("possible_injured", 0),
            "fire_or_smoke_detected": aa.get("fire_detected", False),
            "vehicle_damage_level": aa.get("damage_level", 1),
            "manual_sos_triggered": False,
        }
    else:
        # Manual SOS or voice/sensor trigger — map preliminary_severity
        sev = (payload.preliminary_severity or "unknown").lower()
        risk_map = {"critical": "HIGH", "high": "HIGH", "mid": "MEDIUM", "low": "LOW", "unknown": "MEDIUM"}
        dispatch_input = {
            "manual_sos_triggered": True,
            "reported_risk_level": risk_map.get(sev, "MEDIUM"),
        }
    
    dispatch_result = determine_ambulance_dispatch(dispatch_input)
    sos_doc["ambulance_dispatch"] = dispatch_result
    logger.info(f"🚑 Dispatch recommendation: {dispatch_result['ambulance_type']} ({dispatch_result['priority']})")
    
    result = patient_requests.insert_one(sos_doc)
    request_id = str(result.inserted_id)
    
    # Store in AWS DynamoDB + send SNS alert
    if AWS_ENABLED:
        try:
            dynamo_record = store_accident(
                vehicle_id=f"SOS-{current_user['_id']}",
                latitude=location["lat"],
                longitude=location["lng"],
                impact_force=0,
                status="sos_triggered",
            )
            sns_msg_id = publish_alert(location["lat"], location["lng"], request_id, impact_force=0, device_id=f"SOS-{current_user['_id']}")
            logger.info(f"AWS: DynamoDB={dynamo_record['accident_id']}, SNS={sns_msg_id}")

            # Upload accident image to S3 if provided
            if payload.image_base64:
                try:
                    import base64
                    image_bytes = base64.b64decode(payload.image_base64)
                    s3_result = upload_accident_image(request_id, image_bytes, "image/jpeg")
                    logger.info(f"☁️  Accident image uploaded to S3: {s3_result['s3_key']}")
                except Exception as s3_err:
                    logger.warning(f"S3 image upload failed (non-fatal): {s3_err}")
        except Exception as aws_err:
            logger.warning(f"AWS integration error (non-fatal): {aws_err}")
    
    # Find nearby drivers
    nearby_drivers = list(ambulance_drivers.find({
        "status": "available",
        "active": True,
        "location": {
            "$near": {
                "$geometry": {
                    "type": "Point",
                    "coordinates": [location["lng"], location["lat"]]
                },
                "$maxDistance": 20000  # 20km
            }
        }
    }).limit(3))
    
    # Emit socket event to drivers
    sos_alert_payload = {
        "request_id": request_id,
        "user_id": current_user["_id"],
        "user_name": user_name,
        "blood_group": blood_group,
        "has_medical_allergies": has_medical_allergies,
        "lat": location["lat"],
        "lng": location["lng"],
        "timestamp": datetime.datetime.utcnow().isoformat(),
        "sensor_data": payload.sensor_data,
        "preliminary_severity": payload.preliminary_severity,
        "contact": user_contact,
        "ttl_seconds": 30,
        "has_image": payload.image_base64 is not None,
        "ambulance_dispatch": dispatch_result
    }
    
    # Emit new_sos_request (primary event driver listens for - triggers alarm & vibration)
    await sio.emit('new_sos_request', sos_alert_payload, room='drivers')
    logger.info("📡 Socket.IO 'new_sos_request' emitted to drivers room")
    
    # Also emit sos_alert as backup event
    await sio.emit('sos_alert', sos_alert_payload, room='drivers')
    
    # Broadcast to all connected clients
    await sio.emit('sos_alert', sos_alert_payload)
    
    for driver in nearby_drivers:
        driver_user_id = str(driver["user_id"])
        await sio.emit('new_sos_request', sos_alert_payload, room=f'driver_{driver_user_id}')
        await sio.emit('sos_alert', sos_alert_payload, room=f'driver_{driver_user_id}')
    
    return {
        "success": True,
        "request_id": request_id,
        "status": "pending",
        "nearby_drivers_count": len(nearby_drivers)
    }

@app.get("/api/client/my_requests")
async def get_my_requests(current_user: Dict = Depends(get_current_user)):
    """Get client's SOS requests"""
    if current_user.get("role") != "client":
        raise HTTPException(status_code=403, detail="Only clients can access this")
    
    requests_list = list(patient_requests.find({
        "client_id": str_to_objectid(current_user["_id"])
    }).sort("timestamp", -1))
    
    return {
        "success": True,
        "requests": [serialize_doc(r) for r in requests_list]
    }

# ---------- Driver Endpoints ----------
@app.get("/api/driver/nearby_patients")
async def get_nearby_patients(current_user: Dict = Depends(get_current_user)):
    """Get nearby patient requests for driver"""
    if current_user.get("role") != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can access this")
    
    # Get driver profile
    driver = ambulance_drivers.find_one({"user_id": str_to_objectid(current_user["_id"])})
    if not driver or not driver.get("location"):
        return {"success": True, "requests": []}
    
    # Find nearby pending requests using $near (within 20km), then sort newest first
    nearby_requests = list(patient_requests.find(
        {
            "status": "pending",
            "location": {
                "$near": {
                    "$geometry": driver["location"],
                    "$maxDistance": 20000  # 20km
                }
            }
        },
        {"image_base64": 0}  # Exclude image from list for performance
    ).limit(20))  # Fetch more, then sort and trim

    # Sort newest first by timestamp (fallback to created_at for ESP32 requests)
    nearby_requests.sort(
        key=lambda x: x.get("timestamp") or x.get("created_at") or datetime.datetime.min,
        reverse=True
    )
    nearby_requests = nearby_requests[:10]
    
    results = []
    for r in nearby_requests:
        doc = serialize_doc(r)
        # Check if this request has an image stored
        has_img = patient_requests.count_documents(
            {"_id": r["_id"], "image_base64": {"$exists": True, "$ne": None}}, limit=1
        )
        doc["has_image"] = has_img > 0
        results.append(doc)
    
    return {
        "success": True,
        "requests": results
    }

@app.get("/api/request/{request_id}/image")
async def get_request_image(request_id: str, current_user: Dict = Depends(get_current_user)):
    """Get the accident image for a specific SOS request"""
    if current_user.get("role") not in ("driver", "admin", "client"):
        raise HTTPException(status_code=403, detail="Unauthorized")
    
    doc = patient_requests.find_one(
        {"_id": str_to_objectid(request_id)},
        {"image_base64": 1}
    )
    if not doc:
        raise HTTPException(status_code=404, detail="Request not found")
    
    image_data = doc.get("image_base64")
    if not image_data:
        return {"success": False, "message": "No image available", "image_base64": None}
    
    return {"success": True, "image_base64": image_data}

@app.post("/api/driver/accept_request")
async def accept_request(payload: AcceptRequestRequest, current_user: Dict = Depends(get_current_user)):
    """Driver accepts a request"""
    if current_user.get("role") != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can accept requests")
    
    # Get driver profile
    driver = ambulance_drivers.find_one({"user_id": str_to_objectid(current_user["_id"])})
    if not driver:
        raise HTTPException(status_code=404, detail="Driver profile not found")
    
    # Find and update request
    sos_req = patient_requests.find_one({"_id": str_to_objectid(payload.request_id), "status": "pending"})
    if not sos_req:
        raise HTTPException(status_code=404, detail="Request not found or already accepted")
    
    # Calculate distance and ETA
    distance_km = 3.4
    eta_minutes = 7
    driver_lat = 17.4077701
    driver_lng = 78.4446554
    
    if driver.get("location") and driver["location"].get("coordinates"):
        driver_coords = driver["location"]["coordinates"]
        driver_lng = driver_coords[0]
        driver_lat = driver_coords[1]
        
        if sos_req.get("location") and sos_req["location"].get("coordinates"):
            patient_coords = sos_req["location"]["coordinates"]
            patient_lng = patient_coords[0]
            patient_lat = patient_coords[1]
            
            distance_km = calculate_distance(driver_lat, driver_lng, patient_lat, patient_lng)
            eta_minutes = calculate_eta(distance_km)

    # Update request
    patient_requests.update_one(
        {"_id": sos_req["_id"]},
        {
            "$set": {
                "status": "accepted",
                "driver_id": driver["user_id"],
                "accepted_at": datetime.datetime.utcnow(),
                "distance_km": distance_km,
                "eta_minutes": eta_minutes,
                "driver_location": {
                    "type": "Point",
                    "coordinates": [driver_lng, driver_lat]
                }
            }
        }
    )
    
    # Update driver status
    ambulance_drivers.update_one(
        {"_id": driver["_id"]},
        {"$set": {"status": "busy"}}
    )
    
    # Notify client with complete info
    await sio.emit('driver_accepted', {
        "request_id": payload.request_id,
        "driver_id": str(driver["user_id"]),
        "driver_name": current_user.get("name", "Unknown Driver"),
        "driver_contact": current_user.get("phone", ""),
        "vehicle": driver.get("vehicle_type", "Ambulance"),
        "eta_minutes": eta_minutes,
        "distance_km": distance_km,
        "status": "accepted",
        "location": {
            "lat": driver_lat,
            "lng": driver_lng
        }
    }, room=str(sos_req["client_id"]))
    
    # Notify hospitals with complete information
    hospital_payload = {
        "request_id": payload.request_id,
        "driver_id": str(driver["user_id"]),
        "driver_name": current_user.get("name", "Unknown Driver"),
        "driver_contact": current_user.get("phone", ""),
        "vehicle": driver.get("vehicle_type", "Ambulance"),
        "patient_name": sos_req.get("user_name", "Patient"),
        "patient_contact": sos_req.get("user_contact", ""),
        "blood_group": sos_req.get("blood_group", ""),
        "has_medical_allergies": sos_req.get("has_medical_allergies", False),
        "condition": sos_req.get("condition", "unknown"),
        "preliminary_severity": sos_req.get("preliminary_severity", "unknown"),
        "ambulance_dispatch": sos_req.get("ambulance_dispatch"),
        "status": "accepted",
        "eta_minutes": eta_minutes,
        "distance_km": distance_km,
        "timestamp": datetime.datetime.utcnow().isoformat()
    }
    
    # Send to both 'admin' and 'admins' rooms for reliability (socket service joins 'admins')
    await sio.emit('driver_accepted', hospital_payload, room='admin')
    await sio.emit('incoming_patient', hospital_payload, room='admin')
    await sio.emit('driver_accepted', hospital_payload, room='admins')
    await sio.emit('incoming_patient', hospital_payload, room='admins')
    
    return {
        "success": True,
        "eta_minutes": eta_minutes,
        "distance_km": distance_km
    }

@app.post("/api/driver/submit_assessment")
async def submit_injury_assessment(payload: InjuryAssessmentRequest, current_user: Dict = Depends(get_current_user)):
    """Driver submits injury assessment"""
    if current_user.get("role") != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can submit assessments")
    
    # Update request with assessment
    result = patient_requests.update_one(
        {"_id": str_to_objectid(payload.request_id)},
        {
            "$set": {
                "injury_risk": payload.injury_risk,
                "injury_notes": payload.injury_notes,
                "status": "assessed",
                "assessment_time": datetime.datetime.utcnow()
            }
        }
    )
    
    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Get request details
    req = patient_requests.find_one({"_id": str_to_objectid(payload.request_id)})
    
    # Notify hospital admins — emit to both room names for reliability
    assessment_payload = {
        "request_id": payload.request_id,
        "patient_name": req.get("user_name"),
        "injury_risk": payload.injury_risk,
        "injury_notes": payload.injury_notes,
        "blood_group": req.get("blood_group"),
        "has_medical_allergies": req.get("has_medical_allergies")
    }
    await sio.emit('injury_assessment_submitted', assessment_payload, room='admin')
    await sio.emit('injury_assessment_submitted', assessment_payload, room='admins')
    
    return {"success": True}

@app.post("/api/driver/update_location")
async def update_driver_location(payload: UpdateLocationRequest, current_user: Dict = Depends(get_current_user)):
    """Update driver's current location"""
    if current_user.get("role") != "driver":
        raise HTTPException(status_code=403, detail="Only drivers can update location")
    
    location = payload.location
    ambulance_drivers.update_one(
        {"user_id": str_to_objectid(current_user["_id"])},
        {
            "$set": {
                "location": {
                    "type": "Point",
                    "coordinates": [location["lng"], location["lat"]]
                }
            }
        }
    )
    
    # Find active request assigned to this driver
    req = patient_requests.find_one({
        "driver_id": { "$in": [str_to_objectid(current_user["_id"]), str(current_user["_id"])] },
        "status": {"$in": ["accepted", "enroute", "en_route", "picked_up", "assessed"]}
    })
    
    if req:
        # Calculate new distance & ETA
        if req.get("location") and req["location"].get("coordinates"):
            patient_coords = req["location"]["coordinates"]
            patient_lng = patient_coords[0]
            patient_lat = patient_coords[1]
            
            distance_km = calculate_distance(location["lat"], location["lng"], patient_lat, patient_lng)
            eta_minutes = calculate_eta(distance_km)
            
            # Update request document
            patient_requests.update_one(
                {"_id": req["_id"]},
                {
                    "$set": {
                        "distance_km": distance_km,
                        "eta_minutes": eta_minutes,
                        "driver_location": {
                            "type": "Point",
                            "coordinates": [location["lng"], location["lat"]]
                        }
                    }
                }
            )
            
            # Broadcast update
            broadcast_payload = {
                "driverId": str(current_user["_id"]),
                "latitude": location["lat"],
                "longitude": location["lng"],
                "eta": eta_minutes,
                "distance": distance_km
            }
            
            # Emit to client room
            if req.get("client_id"):
                await sio.emit("driver_location_update", broadcast_payload, room=str(req["client_id"]))
            
            # Emit to hospital rooms
            await sio.emit("driver_location_update", broadcast_payload, room="admin")
            await sio.emit("driver_location_update", broadcast_payload, room="admins")
            
            # Emit to driver room
            await sio.emit("driver_location_update", broadcast_payload, room=f"driver_{str(current_user['_id'])}")
            
            # Broadcast generally
            await sio.emit("driver_location_update", broadcast_payload)
            
            logger.info(f"📡 Location update broadcasted: Driver={current_user['_id']}, Lat={location['lat']}, Lng={location['lng']}, ETA={eta_minutes}m, Dist={distance_km}km")
    
    return {"success": True}

@app.get("/api/ambulance/route/{request_id}")
async def get_ambulance_route(request_id: str):
    """Get route details including coordinates, distance, and ETA"""
    req = patient_requests.find_one({"_id": str_to_objectid(request_id)})
    if not req:
        raise HTTPException(status_code=404, detail="Request not found")
        
    driver_id = req.get("driver_id")
    if not driver_id:
        raise HTTPException(status_code=400, detail="No driver assigned to this request yet")
        
    # Get driver profile for coordinates
    driver = ambulance_drivers.find_one({"user_id": str_to_objectid(driver_id)})
    
    driver_lat = 0.0
    driver_lng = 0.0
    if driver and driver.get("location") and driver["location"].get("coordinates"):
        driver_lng = driver["location"]["coordinates"][0]
        driver_lat = driver["location"]["coordinates"][1]
    elif req.get("driver_location") and req["driver_location"].get("coordinates"):
        driver_lng = req["driver_location"]["coordinates"][0]
        driver_lat = req["driver_location"]["coordinates"][1]
        
    patient_lat = 0.0
    patient_lng = 0.0
    if req.get("location") and req["location"].get("coordinates"):
        patient_lng = req["location"]["coordinates"][0]
        patient_lat = req["location"]["coordinates"][1]
        
    distance_km = req.get("distance_km")
    eta_minutes = req.get("eta_minutes")
    
    if driver_lat and driver_lng and patient_lat and patient_lng:
        if distance_km is None or eta_minutes is None:
            distance_km = calculate_distance(driver_lat, driver_lng, patient_lat, patient_lng)
            eta_minutes = calculate_eta(distance_km)
            
    return {
        "driver_lat": driver_lat,
        "driver_lng": driver_lng,
        "patient_lat": patient_lat,
        "patient_lng": patient_lng,
        "distance_km": distance_km or 0.0,
        "eta_minutes": eta_minutes or 0,
        "status": req.get("status", "pending")
    }

# ---------- Hospital/Admin Endpoints ----------
@app.get("/api/hospital/patient_requests")
async def get_hospital_patient_requests(current_user: Dict = Depends(get_current_user)):
    """Get incoming patient requests for hospital"""
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only hospital admins can access this")
    
    # Get requests that are accepted or in transit
    requests_list = list(patient_requests.find({
        "status": {"$in": ["accepted", "enroute", "en_route", "picked_up", "assessed", "in_transit"]}
    }).sort("timestamp", -1))
    
    return {
        "success": True,
        "requests": [serialize_doc(r) for r in requests_list]
    }

@app.post("/api/hospital/confirm_admission")
async def confirm_admission(payload: ConfirmAdmissionRequest, current_user: Dict = Depends(get_current_user)):
    """Hospital confirms or rejects patient admission"""
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only hospital admins can confirm admissions")
    
    # Update request
    status = "admitted" if payload.action == "accept" else "rejected"
    result = patient_requests.update_one(
        {"_id": str_to_objectid(payload.request_id)},
        {
            "$set": {
                "status": status,
                "hospital_id": str_to_objectid(current_user["_id"]),
                "admission_time": datetime.datetime.utcnow()
            }
        }
    )
    
    if result.modified_count == 0:
        raise HTTPException(status_code=404, detail="Request not found")
    
    # Get request details
    req = patient_requests.find_one({"_id": str_to_objectid(payload.request_id)})
    
    # Notify driver and client
    if payload.action == "accept":
        await sio.emit('hospital_accepted', {
            "request_id": payload.request_id,
            "hospital_name": current_user.get("name")
        }, room=str(req.get("client_id")))
    
    return {"success": True, "status": status}

@app.post("/api/hospital/update_capacity")
async def update_hospital_capacity(payload: UpdateCapacityRequest, current_user: Dict = Depends(get_current_user)):
    """Update hospital capacity"""
    if current_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Only hospital admins can update capacity")
    
    hospitals.update_one(
        {"user_id": str_to_objectid(current_user["_id"])},
        {"$set": {"capacity": payload.capacity}}
    )
    
    return {"success": True}

# ---------- Socket.IO Events ----------
@sio.event
async def connect(sid, environ):
    """Client connected"""
    logger.info(f"Client connected: {sid}")
    await sio.emit('connection_established', {'status': 'connected'}, to=sid)

@sio.event
async def disconnect(sid):
    """Client disconnected"""
    logger.info(f"Client disconnected: {sid}")

@sio.event
async def join(sid, data):
    """Join a room"""
    room = data.get('room')
    if room:
        # `enter_room` is not awaitable for the AsyncServer instance
        sio.enter_room(sid, room)
        logger.info(f"Client {sid} joined room: {room}")

@sio.event
async def leave(sid, data):
    """Leave a room"""
    room = data.get('room')
    if room:
        # `leave_room` is not awaitable for the AsyncServer instance
        sio.leave_room(sid, room)
        logger.info(f"Client {sid} left room: {room}")

# ---------- Health Check ----------
@app.get("/")
async def root():
    """API health check"""
    try:
        mongo_client.server_info()
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)[:100]}"
    
    return {
        "status": "running",
        "service": "Smart-Aid FastAPI",
        "version": "2.0.0",
        "database": db_status,
        "aws_enabled": AWS_ENABLED,
        "ai_provider": "groq",
        "vision_model": VISION_MODEL,
        "chat_model": CHAT_MODEL,
        "groq_api_key_present": bool(GROQ_API_KEY),
    }

@app.get("/health")
async def health(request: Request):
    """Detailed health check"""
    try:
        mongo_client.server_info()
        db_status = "connected"
    except Exception as e:
        db_status = f"error: {str(e)}"
    
    client_ip = request.client.host
    logger.info(f"OK GET    /health                                  | Status: 200 | Database: {db_status} | Client: {client_ip}")
    
    return {
        "status": "healthy",
        "database": db_status,
        "timestamp": datetime.datetime.utcnow().isoformat()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app_fastapi:socket_app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )
