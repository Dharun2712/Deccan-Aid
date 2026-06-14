"""
Weather Integration Service for Risk Prediction
Integrates with OpenWeatherMap API (or fallback to mock data)
"""

import requests
from datetime import datetime
from typing import Dict, Optional
import os

class WeatherService:
    """Weather data service for risk calculation"""
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key or os.getenv('OPENWEATHER_API_KEY')
        self.base_url = "https://api.openweathermap.org/data/2.5/weather"
        self.use_mock = not self.api_key  # Use mock data if no API key
    
    def get_weather(self, lat: float, lng: float) -> Dict:
        """
        Get current weather for location
        
        Returns:
            {
                'condition': str ('clear', 'rainy', 'foggy', etc.),
                'temperature': float (Celsius),
                'humidity': float (percentage),
                'wind_speed': float (m/s),
                'visibility': float (meters),
                'description': str,
                'risk_factor': float (1.0 - 4.0)
            }
        """
        if self.use_mock:
            return self._get_mock_weather(lat, lng)
        
        try:
            params = {
                'lat': lat,
                'lon': lng,
                'appid': self.api_key,
                'units': 'metric'
            }
            
            response = requests.get(self.base_url, params=params, timeout=5)
            response.raise_for_status()
            data = response.json()
            
            return self._parse_weather_data(data)
        
        except Exception as e:
            print(f"⚠️  Weather API error: {e}, using mock data")
            return self._get_mock_weather(lat, lng)
    
    def _parse_weather_data(self, data: Dict) -> Dict:
        """Parse OpenWeatherMap response"""
        weather_main = data['weather'][0]['main'].lower()
        weather_desc = data['weather'][0]['description']
        
        # Map weather conditions to risk categories
        condition_map = {
            'clear': 'clear',
            'clouds': 'cloudy',
            'rain': 'rainy',
            'drizzle': 'rainy',
            'thunderstorm': 'stormy',
            'snow': 'heavy_rain',  # Treat as high risk
            'mist': 'foggy',
            'fog': 'foggy',
            'haze': 'foggy',
        }
        
        condition = condition_map.get(weather_main, 'clear')
        
        # Adjust for intensity
        if 'heavy' in weather_desc.lower() and condition == 'rainy':
            condition = 'heavy_rain'
        
        # Calculate risk factor
        risk_factors = {
            'clear': 1.0,
            'cloudy': 1.1,
            'rainy': 2.5,
            'heavy_rain': 3.5,
            'foggy': 2.8,
            'stormy': 4.0,
        }
        
        return {
            'condition': condition,
            'temperature': data['main']['temp'],
            'humidity': data['main']['humidity'],
            'wind_speed': data['wind']['speed'],
            'visibility': data.get('visibility', 10000),
            'description': weather_desc,
            'risk_factor': risk_factors.get(condition, 1.0),
            'timestamp': datetime.now().isoformat()
        }
    
    def _get_mock_weather(self, lat: float, lng: float) -> Dict:
        """Generate mock weather based on time and season"""
        now = datetime.now()
        hour = now.hour
        month = now.month
        
        # Time-based simulation
        if 22 <= hour or hour < 6:
            # Night/early morning - possible fog
            condition = 'foggy' if hour < 6 and month in [12, 1, 2] else 'clear'
        elif month in [6, 7, 8, 9]:
            # Monsoon season - higher chance of rain
            condition = 'rainy' if hour % 3 == 0 else 'cloudy'
        else:
            condition = 'clear'
        
        risk_factors = {
            'clear': 1.0,
            'cloudy': 1.1,
            'rainy': 2.5,
            'heavy_rain': 3.5,
            'foggy': 2.8,
            'stormy': 4.0,
        }
        
        return {
            'condition': condition,
            'temperature': 28.0,
            'humidity': 65.0,
            'wind_speed': 5.0,
            'visibility': 10000 if condition == 'clear' else 5000 if condition == 'foggy' else 8000,
            'description': f'Mock {condition} weather',
            'risk_factor': risk_factors.get(condition, 1.0),
            'timestamp': now.isoformat(),
            'mock': True
        }
    
    def get_forecast(self, lat: float, lng: float, hours: int = 24) -> Dict:
        """Get weather forecast for risk prediction"""
        # For now, return current weather
        # In production, use forecast API endpoint
        current = self.get_weather(lat, lng)
        
        return {
            'current': current,
            'forecast_hours': hours,
            'alerts': self._check_weather_alerts(current),
            'recommendation': self._get_weather_recommendation(current)
        }
    
    def _check_weather_alerts(self, weather: Dict) -> list:
        """Check for weather-based safety alerts"""
        alerts = []
        
        if weather['condition'] in ['stormy', 'heavy_rain']:
            alerts.append({
                'level': 'critical',
                'message': f"⛈️ Severe weather alert: {weather['condition']}. Avoid travel if possible."
            })
        elif weather['condition'] == 'foggy':
            alerts.append({
                'level': 'high',
                'message': "🌫️ Low visibility due to fog. Drive with caution."
            })
        elif weather['condition'] == 'rainy':
            alerts.append({
                'level': 'medium',
                'message': "🌧️ Rainy conditions. Roads may be slippery."
            })
        
        if weather.get('wind_speed', 0) > 15:
            alerts.append({
                'level': 'medium',
                'message': f"💨 Strong winds detected ({weather['wind_speed']}m/s). Be cautious."
            })
        
        return alerts
    
    def _get_weather_recommendation(self, weather: Dict) -> str:
        """Get driving recommendation based on weather"""
        risk = weather['risk_factor']
        
        if risk >= 3.5:
            return "🚨 CRITICAL: Consider delaying travel due to severe weather"
        elif risk >= 2.5:
            return "⚠️ HIGH RISK: Reduce speed significantly, increase following distance"
        elif risk >= 1.5:
            return "⚡ MODERATE RISK: Drive carefully, stay alert"
        else:
            return "✅ GOOD CONDITIONS: Safe to drive normally"


# Global weather service instance
weather_service = WeatherService()
