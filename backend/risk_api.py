"""
AI Risk Prediction API Endpoints
Integrates with app_fastapi.py
"""

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field
from typing import List, Optional, Tuple
from datetime import datetime
from ai_risk_predictor import risk_predictor
from weather_service import weather_service

# Create router for risk prediction endpoints
risk_router = APIRouter(prefix="/api/risk", tags=["Risk Prediction"])


# Request/Response Models
class LocationRequest(BaseModel):
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
    weather: Optional[str] = Field(None, description="Weather condition")
    road_type: Optional[str] = Field("main_road", description="Type of road")
    speed: Optional[float] = Field(0, ge=0, description="Current speed in km/h")


class WaypointModel(BaseModel):
    lat: float
    lng: float


class RouteRiskRequest(BaseModel):
    waypoints: List[WaypointModel]
    weather: Optional[str] = "clear"


class HeatmapRequest(BaseModel):
    center_lat: float = Field(..., ge=-90, le=90)
    center_lng: float = Field(..., ge=-180, le=180)
    radius_km: float = Field(5.0, ge=0.1, le=50.0)
    grid_size: int = Field(20, ge=5, le=50)


class AccidentRecordRequest(BaseModel):
    lat: float
    lng: float
    severity: str = Field(..., description="minor, moderate, severe, fatal")
    weather: str = "clear"
    road_type: str = "main_road"


# API Endpoints

@risk_router.post("/calculate")
async def calculate_risk(request: LocationRequest):
    """
    Calculate real-time accident risk score for a location
    
    📊 Returns comprehensive risk analysis with:
    - Risk score (0-100)
    - Risk level (low/medium/high/critical)
    - Contributing factors
    - Safety recommendations
    """
    try:
        # Get weather if not provided
        weather = request.weather
        if not weather:
            weather_data = weather_service.get_weather(request.lat, request.lng)
            weather = weather_data['condition']
        
        # Calculate risk
        risk_data = risk_predictor.calculate_risk_score(
            lat=request.lat,
            lng=request.lng,
            weather=weather,
            road_type=request.road_type,
            speed=request.speed
        )
        
        return {
            "success": True,
            "data": risk_data
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Risk calculation failed: {str(e)}")


@risk_router.get("/weather")
async def get_weather(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180)
):
    """
    Get current weather data for location
    
    🌦️ Returns weather conditions integrated with risk factors
    """
    try:
        weather_data = weather_service.get_weather(lat, lng)
        forecast_data = weather_service.get_forecast(lat, lng)
        
        return {
            "success": True,
            "weather": weather_data,
            "forecast": forecast_data
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Weather fetch failed: {str(e)}")


@risk_router.post("/heatmap")
async def generate_heatmap(request: HeatmapRequest):
    """
    Generate accident risk heatmap for a zone
    
    📊 Returns grid-based risk scores for visualization
    - AI-generated risk scores per grid cell
    - Historical accident data overlay
    - Time-based risk factors
    """
    try:
        heatmap_data = risk_predictor.get_zone_risk_heatmap(
            center_lat=request.center_lat,
            center_lng=request.center_lng,
            radius_km=request.radius_km,
            grid_size=request.grid_size
        )
        
        return {
            "success": True,
            "heatmap": heatmap_data
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Heatmap generation failed: {str(e)}")


@risk_router.post("/route-analysis")
async def analyze_route(request: RouteRiskRequest):
    """
    Analyze accident risk along a route
    
    🎯 Returns comprehensive route risk analysis:
    - Average and maximum risk scores
    - High-risk segments identification
    - Segment-by-segment breakdown
    - Overall safety rating
    """
    try:
        # Convert waypoints to tuples
        waypoints = [(wp.lat, wp.lng) for wp in request.waypoints]
        
        route_analysis = risk_predictor.get_route_risk_analysis(
            waypoints=waypoints,
            weather=request.weather
        )
        
        return {
            "success": True,
            "analysis": route_analysis
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Route analysis failed: {str(e)}")


@risk_router.post("/record-accident")
async def record_accident(request: AccidentRecordRequest):
    """
    Record accident data for continuous learning
    
    🔄 Updates AI model with new accident information:
    - Updates road segment risk scores
    - Improves future predictions
    - Builds historical database
    """
    try:
        risk_predictor.record_accident(
            lat=request.lat,
            lng=request.lng,
            severity=request.severity,
            weather=request.weather,
            time=datetime.now(),
            road_type=request.road_type
        )
        
        # Save updated model
        risk_predictor.save_model('models/risk_predictor_model.json')
        
        return {
            "success": True,
            "message": "Accident recorded successfully. Model updated."
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to record accident: {str(e)}")


@risk_router.get("/zone-alerts")
async def get_zone_alerts(
    lat: float = Query(..., ge=-90, le=90),
    lng: float = Query(..., ge=-180, le=180),
    radius_km: float = Query(5.0, ge=0.1, le=50.0)
):
    """
    Get real-time safety alerts for a zone
    
    📍 Returns active safety alerts:
    - Weather-based alerts
    - High-risk zone warnings
    - Time-based cautions
    """
    try:
        # Get weather alerts
        weather_data = weather_service.get_weather(lat, lng)
        weather_alerts = weather_service.get_forecast(lat, lng)['alerts']
        
        # Get risk score
        risk_data = risk_predictor.calculate_risk_score(lat, lng)
        
        # Compile all alerts
        all_alerts = weather_alerts.copy()
        
        # Add risk-based alerts
        if risk_data['risk_score'] > 75:
            all_alerts.append({
                'level': 'critical',
                'message': f"🚨 CRITICAL RISK ZONE: Risk score {risk_data['risk_score']}/100"
            })
        elif risk_data['risk_score'] > 50:
            all_alerts.append({
                'level': 'high',
                'message': f"⚠️ HIGH RISK AREA: Risk score {risk_data['risk_score']}/100"
            })
        
        # Add time-based alerts
        time_period = risk_predictor.get_time_period()
        if time_period == 'night':
            all_alerts.append({
                'level': 'medium',
                'message': "🌙 Night driving: Reduced visibility, stay alert"
            })
        elif time_period in ['morning_rush', 'evening_rush']:
            all_alerts.append({
                'level': 'medium',
                'message': "🚦 Peak traffic hours: Expect congestion"
            })
        
        return {
            "success": True,
            "location": {"lat": lat, "lng": lng},
            "radius_km": radius_km,
            "alert_count": len(all_alerts),
            "alerts": all_alerts,
            "risk_data": risk_data,
            "weather": weather_data
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get zone alerts: {str(e)}")


@risk_router.get("/statistics")
async def get_risk_statistics():
    """
    Get overall risk prediction statistics
    
    📊 Returns system-wide statistics:
    - Total accidents recorded
    - Road segments analyzed
    - Model performance metrics
    """
    try:
        stats = {
            "total_accidents_recorded": len(risk_predictor.accident_history),
            "road_segments_tracked": len(risk_predictor.road_segment_risks),
            "high_risk_segments": sum(
                1 for seg in risk_predictor.road_segment_risks.values()
                if seg['avg_risk'] > 0.7
            ),
            "model_version": "1.0.0",
            "last_updated": datetime.now().isoformat()
        }
        
        return {
            "success": True,
            "statistics": stats
        }
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get statistics: {str(e)}")


# Export router
__all__ = ['risk_router']
