"""
AI-Powered Accident Risk Prediction System
Features:
- Time-based risk prediction (night hours, peak traffic, rainy season)
- Weather-integrated risk scoring
- Road-segment risk probability classification
- Continuous learning from accident data
"""

import math
from datetime import datetime, time
from typing import Dict, List, Tuple
from collections import defaultdict
import json

class AccidentRiskPredictor:
    """AI-based accident risk prediction with temporal and environmental factors"""
    
    def __init__(self):
        # Historical accident data storage
        self.accident_history = []
        self.road_segment_risks = defaultdict(lambda: {'count': 0, 'severity_sum': 0, 'avg_risk': 0.5})
        
        # Time-based risk multipliers
        self.time_risk_factors = {
            'night': 1.8,      # 10 PM - 5 AM (high risk)
            'dawn': 1.5,       # 5 AM - 7 AM (moderate-high risk)
            'morning_rush': 1.4,  # 7 AM - 10 AM (moderate-high risk)
            'day': 1.0,        # 10 AM - 4 PM (baseline risk)
            'evening_rush': 1.6,  # 4 PM - 8 PM (high risk - peak traffic)
            'late_evening': 1.3,  # 8 PM - 10 PM (moderate risk)
        }
        
        # Weather risk multipliers
        self.weather_risk_factors = {
            'clear': 1.0,
            'cloudy': 1.1,
            'rainy': 2.5,      # Very high risk in rain
            'heavy_rain': 3.5,  # Extreme risk
            'foggy': 2.8,      # Very high risk
            'stormy': 4.0,     # Maximum risk
        }
        
        # Season risk multipliers
        self.season_risk_factors = {
            'summer': 1.0,
            'monsoon': 2.0,    # Rainy season
            'winter': 1.2,     # Early morning fog
            'post_monsoon': 1.3,  # Road damage
        }
        
        # Road type risk multipliers
        self.road_type_risk = {
            'highway': 1.8,
            'expressway': 1.5,
            'main_road': 1.3,
            'residential': 0.8,
            'rural': 1.4,
            'mountain': 2.0,
        }
    
    def get_time_period(self, current_time: datetime = None) -> str:
        """Determine time period for risk calculation"""
        if current_time is None:
            current_time = datetime.now()
        
        hour = current_time.hour
        
        if 0 <= hour < 5 or 22 <= hour < 24:
            return 'night'
        elif 5 <= hour < 7:
            return 'dawn'
        elif 7 <= hour < 10:
            return 'morning_rush'
        elif 10 <= hour < 16:
            return 'day'
        elif 16 <= hour < 20:
            return 'evening_rush'
        else:
            return 'late_evening'
    
    def get_season(self, current_date: datetime = None) -> str:
        """Determine season for risk calculation (India-specific)"""
        if current_date is None:
            current_date = datetime.now()
        
        month = current_date.month
        
        if month in [6, 7, 8, 9]:  # June to September
            return 'monsoon'
        elif month in [10, 11]:  # October to November
            return 'post_monsoon'
        elif month in [12, 1, 2]:  # December to February
            return 'winter'
        else:  # March to May
            return 'summer'
    
    def calculate_risk_score(
        self,
        lat: float,
        lng: float,
        weather: str = 'clear',
        road_type: str = 'main_road',
        speed: float = 0,
        current_time: datetime = None
    ) -> Dict:
        """
        Calculate comprehensive risk score for a location
        
        Returns:
            {
                'risk_score': float (0-100),
                'risk_level': str ('low', 'medium', 'high', 'critical'),
                'factors': dict with individual risk contributions,
                'recommendations': list of safety suggestions
            }
        """
        if current_time is None:
            current_time = datetime.now()
        
        # Base risk score
        base_risk = 30.0
        
        # Get time and season multipliers
        time_period = self.get_time_period(current_time)
        season = self.get_season(current_time)
        
        time_factor = self.time_risk_factors.get(time_period, 1.0)
        weather_factor = self.weather_risk_factors.get(weather.lower(), 1.0)
        season_factor = self.season_risk_factors.get(season, 1.0)
        road_factor = self.road_type_risk.get(road_type.lower(), 1.0)
        
        # Road segment historical risk
        segment_key = self._get_segment_key(lat, lng)
        segment_risk = self.road_segment_risks[segment_key]['avg_risk']
        
        # Speed risk (above 60 km/h increases risk)
        speed_factor = 1.0
        if speed > 60:
            speed_factor = 1.0 + (speed - 60) / 100
        elif speed > 80:
            speed_factor = 1.0 + (speed - 60) / 50
        
        # Calculate final risk score
        risk_score = base_risk * time_factor * weather_factor * season_factor * road_factor * speed_factor
        risk_score = risk_score * (0.5 + segment_risk)  # Historical data influence
        
        # Cap at 100
        risk_score = min(risk_score, 100.0)
        
        # Determine risk level
        if risk_score < 30:
            risk_level = 'low'
            risk_color = 'green'
        elif risk_score < 50:
            risk_level = 'medium'
            risk_color = 'yellow'
        elif risk_score < 75:
            risk_level = 'high'
            risk_color = 'orange'
        else:
            risk_level = 'critical'
            risk_color = 'red'
        
        # Generate recommendations
        recommendations = self._generate_recommendations(
            risk_score, time_period, weather, speed, road_type
        )
        
        return {
            'risk_score': round(risk_score, 2),
            'risk_level': risk_level,
            'risk_color': risk_color,
            'factors': {
                'time_period': time_period,
                'time_factor': time_factor,
                'weather': weather,
                'weather_factor': weather_factor,
                'season': season,
                'season_factor': season_factor,
                'road_type': road_type,
                'road_factor': road_factor,
                'speed': speed,
                'speed_factor': round(speed_factor, 2),
                'segment_risk': round(segment_risk, 2),
            },
            'recommendations': recommendations,
            'timestamp': current_time.isoformat()
        }
    
    def _generate_recommendations(
        self,
        risk_score: float,
        time_period: str,
        weather: str,
        speed: float,
        road_type: str
    ) -> List[str]:
        """Generate safety recommendations based on risk factors"""
        recommendations = []
        
        # Time-based recommendations
        if time_period == 'night':
            recommendations.append("🌙 Night driving: Use high beams when safe, stay alert for wildlife")
        elif time_period == 'dawn':
            recommendations.append("🌅 Dawn hours: Watch for reduced visibility and early morning fog")
        elif time_period in ['morning_rush', 'evening_rush']:
            recommendations.append("🚦 Peak traffic: Maintain safe distance, expect sudden stops")
        
        # Weather recommendations
        if weather in ['rainy', 'heavy_rain']:
            recommendations.append("🌧️ Rainy conditions: Reduce speed by 30%, increase following distance")
        elif weather == 'foggy':
            recommendations.append("🌫️ Low visibility: Use fog lights, drive slowly, use road markings")
        elif weather == 'stormy':
            recommendations.append("⛈️ Storm warning: Consider delaying travel if possible")
        
        # Speed recommendations
        if speed > 80:
            recommendations.append("⚠️ High speed detected: Reduce speed to safe limits")
        elif speed > 60 and road_type in ['residential', 'rural']:
            recommendations.append("🏘️ Speed caution: Reduce speed in populated/rural areas")
        
        # Road type recommendations
        if road_type == 'highway':
            recommendations.append("🛣️ Highway: Stay in lane, check mirrors frequently")
        elif road_type == 'mountain':
            recommendations.append("⛰️ Mountain road: Use lower gears, watch for sharp turns")
        
        # Risk level recommendations
        if risk_score > 75:
            recommendations.append("🚨 CRITICAL RISK: Consider alternative route or delay travel")
        elif risk_score > 50:
            recommendations.append("⚠️ High risk zone: Stay extra alert and cautious")
        
        return recommendations
    
    def _get_segment_key(self, lat: float, lng: float, precision: int = 3) -> str:
        """Get road segment identifier (grid-based)"""
        # Round coordinates to create segments (precision 3 = ~100m segments)
        segment_lat = round(lat, precision)
        segment_lng = round(lng, precision)
        return f"{segment_lat},{segment_lng}"
    
    def record_accident(
        self,
        lat: float,
        lng: float,
        severity: str,
        weather: str,
        time: datetime,
        road_type: str
    ):
        """Record accident for continuous learning"""
        segment_key = self._get_segment_key(lat, lng)
        
        # Severity to numeric score
        severity_score = {
            'minor': 0.3,
            'moderate': 0.6,
            'severe': 0.9,
            'fatal': 1.0
        }.get(severity.lower(), 0.5)
        
        # Update segment risk
        segment_data = self.road_segment_risks[segment_key]
        segment_data['count'] += 1
        segment_data['severity_sum'] += severity_score
        segment_data['avg_risk'] = segment_data['severity_sum'] / segment_data['count']
        
        # Store in history
        accident_record = {
            'lat': lat,
            'lng': lng,
            'severity': severity,
            'severity_score': severity_score,
            'weather': weather,
            'time': time.isoformat(),
            'road_type': road_type,
            'segment_key': segment_key
        }
        self.accident_history.append(accident_record)
        
        print(f"✅ Recorded accident at {segment_key}, new avg risk: {segment_data['avg_risk']:.2f}")
    
    def get_zone_risk_heatmap(
        self,
        center_lat: float,
        center_lng: float,
        radius_km: float = 5.0,
        grid_size: int = 20
    ) -> Dict:
        """
        Generate risk heatmap for a zone
        
        Returns: Grid of risk scores for visualization
        """
        heatmap_data = []
        
        # Calculate grid boundaries
        lat_offset = radius_km / 111.0  # 1 degree lat ≈ 111 km
        lng_offset = radius_km / (111.0 * math.cos(math.radians(center_lat)))
        
        lat_min = center_lat - lat_offset
        lat_max = center_lat + lat_offset
        lng_min = center_lng - lng_offset
        lng_max = center_lng + lng_offset
        
        lat_step = (lat_max - lat_min) / grid_size
        lng_step = (lng_max - lng_min) / grid_size
        
        # Generate grid
        current_time = datetime.now()
        
        for i in range(grid_size):
            for j in range(grid_size):
                grid_lat = lat_min + i * lat_step
                grid_lng = lng_min + j * lng_step
                
                # Calculate risk for this grid cell
                segment_key = self._get_segment_key(grid_lat, grid_lng)
                segment_risk = self.road_segment_risks[segment_key]['avg_risk']
                
                # Get base risk score (simplified)
                time_period = self.get_time_period(current_time)
                time_factor = self.time_risk_factors.get(time_period, 1.0)
                
                base_risk = 30.0 * time_factor * (0.5 + segment_risk)
                
                heatmap_data.append({
                    'lat': grid_lat,
                    'lng': grid_lng,
                    'risk_score': round(base_risk, 2),
                    'accident_count': self.road_segment_risks[segment_key]['count']
                })
        
        return {
            'center': {'lat': center_lat, 'lng': center_lng},
            'radius_km': radius_km,
            'grid_size': grid_size,
            'heatmap': heatmap_data,
            'timestamp': current_time.isoformat()
        }
    
    def get_route_risk_analysis(
        self,
        waypoints: List[Tuple[float, float]],
        weather: str = 'clear',
        current_time: datetime = None
    ) -> Dict:
        """Analyze risk along a route"""
        if current_time is None:
            current_time = datetime.now()
        
        segment_risks = []
        total_risk = 0.0
        
        for lat, lng in waypoints:
            risk_data = self.calculate_risk_score(
                lat, lng, weather=weather, current_time=current_time
            )
            segment_risks.append(risk_data)
            total_risk += risk_data['risk_score']
        
        avg_risk = total_risk / len(waypoints) if waypoints else 0
        
        # Find high-risk segments
        high_risk_segments = [
            r for r in segment_risks if r['risk_score'] > 60
        ]
        
        return {
            'average_risk': round(avg_risk, 2),
            'max_risk': max(r['risk_score'] for r in segment_risks) if segment_risks else 0,
            'high_risk_count': len(high_risk_segments),
            'segments': segment_risks,
            'high_risk_segments': high_risk_segments,
            'overall_level': 'critical' if avg_risk > 70 else 'high' if avg_risk > 50 else 'medium' if avg_risk > 30 else 'low'
        }
    
    def save_model(self, filepath: str):
        """Save learned data to file"""
        data = {
            'accident_history': self.accident_history,
            'road_segment_risks': dict(self.road_segment_risks)
        }
        with open(filepath, 'w') as f:
            json.dump(data, f)
        print(f"✅ Model saved to {filepath}")
    
    def load_model(self, filepath: str):
        """Load learned data from file"""
        try:
            with open(filepath, 'r') as f:
                data = json.load(f)
            self.accident_history = data.get('accident_history', [])
            self.road_segment_risks = defaultdict(
                lambda: {'count': 0, 'severity_sum': 0, 'avg_risk': 0.5},
                data.get('road_segment_risks', {})
            )
            print(f"✅ Model loaded from {filepath}")
            print(f"   Loaded {len(self.accident_history)} accident records")
            print(f"   Loaded {len(self.road_segment_risks)} road segments")
        except FileNotFoundError:
            print(f"⚠️  No existing model found at {filepath}")
        except Exception as e:
            print(f"❌ Error loading model: {e}")


# Global predictor instance
risk_predictor = AccidentRiskPredictor()

# Try to load existing model on startup
try:
    risk_predictor.load_model('models/risk_predictor_model.json')
except:
    pass
