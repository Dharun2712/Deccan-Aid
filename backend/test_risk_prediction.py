"""
AI Risk Prediction System - Test & Demo Script
Run this to test the risk prediction features
"""

from ai_risk_predictor import risk_predictor
from weather_service import weather_service
from datetime import datetime
import json

def test_risk_calculation():
    """Test basic risk calculation"""
    print("\n" + "="*70)
    print("🎯 TEST 1: Basic Risk Calculation")
    print("="*70)
    
    # Test location (M Kumarasamy College area - Karur)
    lat, lng = 10.960, 78.060
    
    # Get weather
    weather_data = weather_service.get_weather(lat, lng)
    print(f"\n📍 Location: {lat}, {lng}")
    print(f"🌦️  Weather: {weather_data['condition']} ({weather_data['description']})")
    
    # Calculate risk
    risk_data = risk_predictor.calculate_risk_score(
        lat=lat,
        lng=lng,
        weather=weather_data['condition'],
        road_type='main_road',
        speed=50
    )
    
    print(f"\n📊 RISK ANALYSIS:")
    print(f"   Risk Score: {risk_data['risk_score']}/100")
    print(f"   Risk Level: {risk_data['risk_level'].upper()} ({risk_data['risk_color']})")
    print(f"   Time Period: {risk_data['factors']['time_period']}")
    print(f"   Time Factor: {risk_data['factors']['time_factor']}x")
    print(f"   Weather Factor: {risk_data['factors']['weather_factor']}x")
    print(f"   Speed: {risk_data['factors']['speed']} km/h")
    
    print(f"\n💡 RECOMMENDATIONS:")
    for i, rec in enumerate(risk_data['recommendations'], 1):
        print(f"   {i}. {rec}")
    
    return risk_data


def test_time_based_risk():
    """Test risk at different times"""
    print("\n" + "="*70)
    print("⏰ TEST 2: Time-Based Risk Prediction")
    print("="*70)
    
    lat, lng = 10.960, 78.060
    
    # Test different times
    test_times = [
        datetime(2026, 2, 20, 2, 0),   # Night
        datetime(2026, 2, 20, 8, 0),   # Morning rush
        datetime(2026, 2, 20, 14, 0),  # Day
        datetime(2026, 2, 20, 18, 0),  # Evening rush
    ]
    
    for test_time in test_times:
        risk = risk_predictor.calculate_risk_score(
            lat, lng, weather='clear', current_time=test_time
        )
        print(f"\n{test_time.strftime('%H:%M')} - "
              f"{risk['factors']['time_period'].upper()}: "
              f"Risk {risk['risk_score']}/100 ({risk['risk_level']})")


def test_weather_impact():
    """Test different weather conditions"""
    print("\n" + "="*70)
    print("🌦️  TEST 3: Weather Impact on Risk")
    print("="*70)
    
    lat, lng = 10.960, 78.060
    
    weather_conditions = ['clear', 'cloudy', 'rainy', 'heavy_rain', 'foggy', 'stormy']
    
    for weather in weather_conditions:
        risk = risk_predictor.calculate_risk_score(lat, lng, weather=weather, speed=60)
        print(f"\n{weather.upper():15} -> Risk: {risk['risk_score']:5.1f}/100 "
              f"({risk['risk_level']}, {risk['risk_color']})")


def test_heatmap_generation():
    """Test heatmap generation"""
    print("\n" + "="*70)
    print("📊 TEST 4: Risk Heatmap Generation")
    print("="*70)
    
    # Center around M Kumarasamy College
    lat, lng = 10.960, 78.060
    
    print(f"\n📍 Generating heatmap for area around {lat}, {lng}")
    print(f"   Radius: 5 km")
    print(f"   Grid: 10x10 cells")
    
    heatmap = risk_predictor.get_zone_risk_heatmap(
        center_lat=lat,
        center_lng=lng,
        radius_km=5.0,
        grid_size=10
    )
    
    print(f"\n✅ Generated {len(heatmap['heatmap'])} grid cells")
    
    # Show sample cells
    print(f"\n📊 Sample risk scores:")
    for i, cell in enumerate(heatmap['heatmap'][:5], 1):
        print(f"   Cell {i}: ({cell['lat']:.4f}, {cell['lng']:.4f}) -> "
              f"Risk: {cell['risk_score']}/100")
    
    return heatmap


def test_accident_recording():
    """Test accident recording and learning"""
    print("\n" + "="*70)
    print("🔄 TEST 5: Accident Recording & Learning")
    print("="*70)
    
    # Simulate accidents at different locations
    accidents = [
        {'lat': 10.960, 'lng': 78.060, 'severity': 'moderate', 'weather': 'rainy'},
        {'lat': 10.962, 'lng': 78.058, 'severity': 'minor', 'weather': 'clear'},
        {'lat': 10.960, 'lng': 78.060, 'severity': 'severe', 'weather': 'foggy'},
    ]
    
    print(f"\n📝 Recording {len(accidents)} accidents...")
    
    for accident in accidents:
        risk_predictor.record_accident(
            lat=accident['lat'],
            lng=accident['lng'],
            severity=accident['severity'],
            weather=accident['weather'],
            time=datetime.now(),
            road_type='main_road'
        )
    
    # Check updated risk for that location
    updated_risk = risk_predictor.calculate_risk_score(10.960, 78.060)
    print(f"\n📊 Updated risk score for accident-prone area: {updated_risk['risk_score']}/100")
    print(f"   Segment risk factor: {updated_risk['factors']['segment_risk']}")


def test_route_analysis():
    """Test route risk analysis"""
    print("\n" + "="*70)
    print("🎯 TEST 6: Route Risk Analysis")
    print("="*70)
    
    # Sample route waypoints (M Kumarasamy College to nearby hospitals)
    route = [
        (10.960, 78.060),   # Start: College
        (10.962, 78.058),   # Waypoint 1
        (10.964, 78.056),   # Waypoint 2
        (10.965, 78.054),   # End: Hospital
    ]
    
    print(f"\n🛣️  Analyzing route with {len(route)} waypoints...")
    
    analysis = risk_predictor.get_route_risk_analysis(route, weather='clear')
    
    print(f"\n📊 ROUTE RISK ANALYSIS:")
    print(f"   Average Risk: {analysis['average_risk']}/100")
    print(f"   Maximum Risk: {analysis['max_risk']}/100")
    print(f"   Overall Level: {analysis['overall_level'].upper()}")
    print(f"   High-Risk Segments: {analysis['high_risk_count']}")
    
    if analysis['high_risk_segments']:
        print(f"\n⚠️  HIGH RISK AREAS:")
        for seg in analysis['high_risk_segments'][:3]:
            print(f"      Risk {seg['risk_score']}/100 at {seg['factors']['time_period']}")


def test_zone_alerts():
    """Test zone-based alerts"""
    print("\n" + "="*70)
    print("📍 TEST 7: Zone-Based Safety Alerts")
    print("="*70)
    
    lat, lng = 10.960, 78.060
    
    # Get weather and alerts
    weather_data = weather_service.get_weather(lat, lng)
    forecast = weather_service.get_forecast(lat, lng)
    
    print(f"\n📍 Location: {lat}, {lng}")
    print(f"🌦️  Weather: {weather_data['condition']}")
    
    if forecast['alerts']:
        print(f"\n🚨 ACTIVE ALERTS:")
        for alert in forecast['alerts']:
            print(f"   [{alert['level'].upper()}] {alert['message']}")
    else:
        print(f"\n✅ No active alerts")
    
    print(f"\n💡 Recommendation: {forecast['recommendation']}")


def run_all_tests():
    """Run all tests"""
    print("\n" + "="*70)
    print("🚀 AI ACCIDENT RISK PREDICTION SYSTEM - DEMO")
    print("="*70)
    print(f"   Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"   Location: M Kumarasamy College of Engineering, Karur")
    print("="*70)
    
    try:
        # Run all tests
        test_risk_calculation()
        test_time_based_risk()
        test_weather_impact()
        test_heatmap_generation()
        test_accident_recording()
        test_route_analysis()
        test_zone_alerts()
        
        # Save model
        print("\n" + "="*70)
        print("💾 Saving Learned Data...")
        print("="*70)
        risk_predictor.save_model('models/risk_predictor_model.json')
        
        print("\n" + "="*70)
        print("✅ ALL TESTS COMPLETED SUCCESSFULLY!")
        print("="*70)
        print("\n📊 System Statistics:")
        print(f"   Total Accidents Recorded: {len(risk_predictor.accident_history)}")
        print(f"   Road Segments Tracked: {len(risk_predictor.road_segment_risks)}")
        print(f"   Model Status: ✅ Ready for prediction")
        print("="*70)
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    run_all_tests()
