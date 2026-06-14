# 🎯 AI-Powered Accident Risk Prediction System

## Overview

Advanced AI-based accident risk prediction system with real-time analysis, weather integration, and continuous learning capabilities.

## 🌟 Key Features

### 📊 AI-Generated Accident Risk Heatmaps
- Grid-based risk visualization
- Historical accident data overlay
- Real-time risk score calculation
- Customizable radius and grid resolution

### ⏰ Time-Based Risk Prediction
- **Night Hours (10 PM - 5 AM)**: 1.8x risk multiplier
- **Morning Rush (7 AM - 10 AM)**: 1.4x risk multiplier
- **Evening Rush (4 PM - 8 PM)**: 1.6x risk multiplier
- **Day Hours (10 AM - 4 PM)**: Baseline risk

### 🌦️ Weather-Integrated Risk Scoring
- **Clear**: 1.0x (baseline)
- **Cloudy**: 1.1x
- **Rainy**: 2.5x
- **Heavy Rain**: 3.5x
- **Foggy**: 2.8x
- **Stormy**: 4.0x (maximum risk)

### 📍 Real-Time Zone-Based Safety Alerts
- Active weather alerts
- High-risk zone warnings
- Time-based cautions
- Speed-based recommendations

### 🔄 Continuous Learning from New Accident Data
- Automatic risk model updates
- Road segment risk tracking
- Severity-weighted learning
- Persistent model storage

### 🎯 Road-Segment Risk Probability Classification
- Grid-based segmentation (~100m resolution)
- Historical accident frequency
- Severity-weighted scoring
- Low/Medium/High/Critical classifications

## 📁 File Structure

```
backend/
├── ai_risk_predictor.py      # Core AI prediction engine
├── weather_service.py         # Weather integration
├── risk_api.py               # FastAPI endpoints
├── test_risk_prediction.py   # Test & demo script
├── models/                   # Saved models directory
│   └── risk_predictor_model.json
└── app_fastapi.py            # Main app (integrated)
```

## 🚀 API Endpoints

### 1. Calculate Risk Score
```http
POST /api/risk/calculate
Content-Type: application/json

{
  "lat": 10.960,
  "lng": 78.060,
  "weather": "rainy",
  "road_type": "highway",
  "speed": 80
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "risk_score": 72.5,
    "risk_level": "high",
    "risk_color": "orange",
    "factors": {
      "time_period": "evening_rush",
      "time_factor": 1.6,
      "weather": "rainy",
      "weather_factor": 2.5,
      "speed": 80,
      "speed_factor": 1.4
    },
    "recommendations": [
      "🌧️ Rainy conditions: Reduce speed by 30%",
      "🚦 Peak traffic: Maintain safe distance"
    ]
  }
}
```

### 2. Get Weather Data
```http
GET /api/risk/weather?lat=10.960&lng=78.060
```

### 3. Generate Risk Heatmap
```http
POST /api/risk/heatmap
Content-Type: application/json

{
  "center_lat": 10.960,
  "center_lng": 78.060,
  "radius_km": 5.0,
  "grid_size": 20
}
```

### 4. Analyze Route Risk
```http
POST /api/risk/route-analysis
Content-Type: application/json

{
  "waypoints": [
    {"lat": 10.960, "lng": 78.060},
    {"lat": 10.962, "lng": 78.058},
    {"lat": 10.965, "lng": 78.054}
  ],
  "weather": "clear"
}
```

### 5. Record Accident (Learning)
```http
POST /api/risk/record-accident
Content-Type: application/json

{
  "lat": 10.960,
  "lng": 78.060,
  "severity": "moderate",
  "weather": "rainy",
  "road_type": "highway"
}
```

### 6. Get Zone Alerts
```http
GET /api/risk/zone-alerts?lat=10.960&lng=78.060&radius_km=5.0
```

### 7. Get Statistics
```http
GET /api/risk/statistics
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
cd backend
python test_risk_prediction.py
```

**Test Coverage:**
- ✅ Basic risk calculation
- ✅ Time-based risk prediction
- ✅ Weather impact analysis
- ✅ Heatmap generation
- ✅ Accident recording & learning
- ✅ Route risk analysis
- ✅ Zone-based safety alerts

## 📊 Risk Score Calculation

```python
risk_score = base_risk × time_factor × weather_factor × 
             season_factor × road_factor × speed_factor × 
             (0.5 + segment_historical_risk)
```

**Risk Levels:**
- 🟢 **Low** (0-30): Safe conditions
- 🟡 **Medium** (30-50): Normal caution
- 🟠 **High** (50-75): Extra caution required
- 🔴 **Critical** (75-100): Dangerous conditions

## 🌐 Weather Integration

### API Support
- OpenWeatherMap API (production)
- Mock weather data (fallback)

### Configuration
Set environment variable:
```bash
export OPENWEATHER_API_KEY="your_api_key_here"
```

Or use automatic mock data for testing.

## 🔄 Continuous Learning

The system automatically:
1. Records accident location, severity, and conditions
2. Updates road segment risk scores
3. Weights by severity (minor: 0.3, moderate: 0.6, severe: 0.9, fatal: 1.0)
4. Saves model to persistent storage
5. Improves future predictions

## 📈 Integration with LifeLink

The risk prediction system integrates with:
- 🚑 **Driver Dashboard**: Real-time risk alerts during transit
- 📱 **Client App**: Route safety assessment before travel
- 🏥 **Hospital Dashboard**: Incoming patient risk assessment
- 🎯 **ESP32 Accident Detection**: Enhanced severity prediction

## 🎯 Use Cases

1. **Pre-Travel Risk Assessment** 
   - Check route safety before departure
   - Get alternative route recommendations
   
2. **Real-Time Navigation Alerts**
   - Dynamic risk updates during travel
   - Weather-based speed recommendations
   
3. **Emergency Response Optimization**
   - Safest ambulance routing
   - Risk-aware hospital selection
   
4. **Traffic Safety Analysis**
   - Identify high-risk zones
   - Plan preventive measures
   
5. **Insurance & Fleet Management**
   - Driver behavior monitoring
   - Risk-based premium calculation

## 🚧 Future Enhancements

- [ ] Deep learning model integration (TensorFlow/PyTorch)
- [ ] Traffic density integration
- [ ] Road condition sensors (pothole detection)
- [ ] Vehicle type-specific risk models
- [ ] Social media data for real-time incidents
- [ ] Historical pattern analysis (holidays, festivals)
- [ ] Driver fatigue detection integration

## 📝 License

Part of LifeLink Smart Ambulance System
© 2026 M Kumarasamy College of Engineering

## 👥 Contributors

- AI Risk Prediction Engine
- Weather Integration Service
- Continuous Learning Pipeline
- Heatmap Visualization System

---

**Status:** ✅ Production Ready
**Version:** 1.0.0
**Last Updated:** February 20, 2026
