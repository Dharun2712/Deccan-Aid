import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/sos_service.dart';
import '../services/socket_service.dart';
import '../services/accident_detector_service.dart';
import '../services/notification_service.dart';
import '../models/hospital_data.dart';
import '../widgets/hospital_list_card.dart';
import '../widgets/voice_emergency_widget.dart';
import 'emergency_voice_activation_page.dart';
import '../services/native_emergency_service.dart';
import '../services/voice_emergency_service.dart';
import 'sos_confirmation_modal.dart';
import '../config/api_config.dart';
import 'sos_active_screen.dart';
import 'user_profile_page.dart';
import 'accident_image_analysis_page.dart';
import 'first_aid_chat_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ClientDashboardEnhanced extends StatefulWidget {
  const ClientDashboardEnhanced({Key? key}) : super(key: key);

  @override
  State<ClientDashboardEnhanced> createState() =>
      _ClientDashboardEnhancedState();
}

class _ClientDashboardEnhancedState extends State<ClientDashboardEnhanced> {
  final _authService = AuthService();
  final _locationService = LocationService();
  final _sosService = SOSService();
  final _socketService = SocketService();
  final _accidentDetector = AccidentDetectorService();
  final _notificationService = NotificationService();
  final _nativeEmergency = NativeEmergencyService();

  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _autoSOSEnabled = false;
  bool _sosActive = false;
  String? _assignedDriverId;
  Map<String, dynamic>? _assignedHospital;
  List<Map<String, dynamic>> _requestHistory = [];
  DateTime? _historyCleared;
  String? _userName;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _ambulanceLocation;
  Position? _driverPosition;
  double? _distanceToDriver;
  Timer? _locationUpdateTimer;
  String? _activeRequestId;

  // Voice Emergency Service states
  final _voiceService = VoiceEmergencyService();
  VoiceEmergencyStatus _voiceStatus = VoiceEmergencyStatus.idle;
  String _voiceTranscription = '';
  bool _voiceActive = false;
  String? _voiceSelectedLanguage;

  @override
  void initState() {
    super.initState();
    _initDashboard();
  }

  Future<void> _initDashboard() async {
    _userName = await _authService.getUserId();
    _nativeEmergency.initialize();
    await _notificationService.initialize();
    await _loadHistoryClearTimestamp();
    await _getCurrentLocation();
    _setupSocketListeners();
    _loadRequestHistory();
    _initVoiceService();
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null && mounted) {
      setState(() {
        _currentPosition = position;
        _updateMapMarkers();
      });
    }
  }

  void _setupSocketListeners() {
    final userId = _authService.getUserId();
    userId.then((id) {
      if (id != null) {
        _socketService.connect(ApiConfig.baseUrl, id, 'client');

        // Helper to handle request assignment / accept
        final handleAccepted = (data) {
          print('[ClientDashboard] Driver accepted event received: $data');

          if (mounted) {
            setState(() {
              _sosActive = true;
              _assignedDriverId = data['driver_id'] ?? data['driverId'];
              _activeRequestId = data['request_id'] ?? data['requestId'];
              
              if (data['location'] != null) {
                final lat = data['location']['lat'] ?? data['location']['latitude'];
                final lng = data['location']['lng'] ?? data['location']['longitude'];
                if (lat != null && lng != null) {
                  _ambulanceLocation = LatLng((lat as num).toDouble(), (lng as num).toDouble());
                  _driverPosition = Position(
                    latitude: (lat as num).toDouble(),
                    longitude: (lng as num).toDouble(),
                    timestamp: DateTime.now(),
                    accuracy: 0, altitude: 0, altitudeAccuracy: 0, heading: 0, headingAccuracy: 0, speed: 0, speedAccuracy: 0,
                  );
                }
              }
              
              if (data['distance_km'] != null || data['distance'] != null) {
                final dist = data['distance_km'] ?? data['distance'];
                _distanceToDriver = (dist as num).toDouble() * 1000; // Store in meters
              }
            });

            // Calculate ETA for notification
            String eta = 'Calculating...';
            String distance = 'Calculating...';
            if (_distanceToDriver != null) {
              distance = '${(_distanceToDriver! / 1000).toStringAsFixed(1)} km';
              final etaMinutes = (_distanceToDriver! / 1000 / 40 * 60).ceil();
              eta = '$etaMinutes min';
            }

            print('[ClientDashboard] Triggering background notification');

            // Show background notification
            _notificationService.showDriverAcceptedNotification(
              driverName: data['driver_name'] ?? 'Driver',
              vehicle: data['vehicle'] ?? 'Ambulance',
              eta: eta,
              distance: distance,
            );

            _showAcceptanceNotification(
              driverName: data['driver_name'] ?? 'Driver',
              vehicle: data['vehicle'] ?? 'Ambulance',
            );
            _showSnackBar(
              '🚑 Ambulance assigned! Driver on the way.',
              backgroundColor: Colors.green,
            );
            _startDriverLocationTracking();
            _loadRequestHistory(); // Refresh to show latest status
            _updateMapMarkers();
            if (_ambulanceLocation != null) {
              _fitMapToMarkers();
            }
          }
        };

        // Driver accepted - REAL-TIME
        _socketService.onSOSAccepted((data) => handleAccepted(data));
        _socketService.socket?.on('driver_accepted', (data) => handleAccepted(data));

        // Driver location updates - LIVE TRACKING
        _socketService.socket?.on('driver_location_update', (data) {
          final incomingDriverId = data['driverId'] ?? data['driver_id'];
          if (mounted && (incomingDriverId == _assignedDriverId || _assignedDriverId == null)) {
            setState(() {
              if (incomingDriverId != null && _assignedDriverId == null) {
                _assignedDriverId = incomingDriverId;
              }
              _driverPosition = Position(
                latitude: (data['latitude'] ?? data['lat'] as num).toDouble(),
                longitude: (data['longitude'] ?? data['lng'] as num).toDouble(),
                timestamp: DateTime.now(),
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
              _ambulanceLocation = LatLng(
                (data['latitude'] ?? data['lat'] as num).toDouble(),
                (data['longitude'] ?? data['lng'] as num).toDouble(),
              );
              if (data['distance'] != null) {
                _distanceToDriver = (data['distance'] as num).toDouble() * 1000; // convert km to meters
              }
              _updateMapMarkers();
              
              if (data['distance'] == null) {
                _calculateDistanceToDriver();
              }
              _fitMapToMarkers();
            });
          }
        });

        // Hospital accepted - FINAL CONFIRMATION
        _socketService.socket?.on('hospital_accepted', (data) {
          if (mounted && data['request_id'] == _activeRequestId) {
            final hospitalName = data['hospital_name'] ?? 'Hospital';
            _showHospitalAcceptanceDialog(hospitalName);
            _showSnackBar(
              '🏥 $hospitalName confirmed admission!',
              backgroundColor: Colors.blue,
            );
          }
        });

        // Driver arrived notification
        _socketService.socket?.on('driver_arrived', (data) {
          if (mounted && data['request_id'] == _activeRequestId) {
            _showDriverArrivedDialog();
          }
        });
      }
    });
  }

  void _startDriverLocationTracking() {
    _locationUpdateTimer?.cancel();
    _locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_assignedDriverId != null && _sosActive) {
        // Request driver location update from server
        _socketService.socket?.emit('request_driver_location', {
          'driver_id': _assignedDriverId,
        });
      } else {
        timer.cancel();
      }
    });
  }

  void _calculateDistanceToDriver() {
    if (_currentPosition != null && _driverPosition != null) {
      final distance = _locationService.calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _driverPosition!.latitude,
        _driverPosition!.longitude,
      );
      setState(() {
        _distanceToDriver = distance;
      });
    }
  }

  void _showAcceptanceNotification({String? driverName, String? vehicle}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green.shade50,
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Request Accepted!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚑 An ambulance driver has accepted your request!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (driverName != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Driver: $driverName',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (vehicle != null) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_car,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Vehicle: $vehicle',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  const Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ambulance is on the way',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '📍 Track the ambulance location in real-time on the map below',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Got it!', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showHospitalAcceptanceDialog(String hospitalName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.blue.shade50,
        title: Row(
          children: [
            Icon(Icons.local_hospital, color: Colors.blue.shade700, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Hospital Confirmed!',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏥 $hospitalName has confirmed your admission!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Bed prepared and ready',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.medical_services, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Medical team on standby',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '⏱️ You will be taken directly to the emergency department',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Understood', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showDriverArrivedDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green.shade50,
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.green.shade700, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Driver Arrived!',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🚑 The ambulance has arrived at your location!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_walk,
                        color: Colors.orange,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please proceed to the ambulance',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.healing, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Medical assistance ready',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '🏥 You will be transported to the hospital shortly',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('OK', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _initVoiceService() {
    _voiceSelectedLanguage = _voiceService.selectedLanguageCode;
    
    _voiceService.onStatusChanged = (status) {
      if (mounted) {
        setState(() {
          _voiceStatus = status;
          _voiceActive = _voiceService.isActive;
        });
      }
    };

    _voiceService.onTranscription = (text, isFinal) {
      if (mounted) {
        setState(() => _voiceTranscription = text);
      }
    };

    _voiceService.onEmergencyDetected = (result) {
      if (mounted) {
        if (result.intent == VoiceIntent.emergencyRequest) {
          setState(() => _sosActive = true);
          _loadRequestHistory();
          _showSnackBar(
            'Voice SOS sent! Searching for nearest ambulance...',
            backgroundColor: Colors.red,
          );
        }
      }
    };
    
    // Sync initial status
    _voiceActive = _voiceService.isActive;
    _voiceStatus = _voiceService.status;
  }

  Widget _buildFloatingActions() {
    final isVoiceActive = _voiceActive;
    final isVoiceEmergency = _voiceStatus == VoiceEmergencyStatus.triggeringEmergency;
    final isVoiceWake = _voiceStatus == VoiceEmergencyStatus.wakeWordDetected ||
        _voiceStatus == VoiceEmergencyStatus.capturingCommand;

    Color voiceBgColor = Colors.grey.shade700;
    if (isVoiceEmergency) {
      voiceBgColor = Colors.red;
    } else if (isVoiceWake) {
      voiceBgColor = Colors.orange;
    } else if (isVoiceActive) {
      voiceBgColor = Colors.teal;
    }

    return Positioned(
      left: 16,
      bottom: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Voice Emergency Assistant (Circular FAB)
          Tooltip(
            key: const ValueKey('voice_assistant_tooltip'),
            message: 'Voice Emergency Assistant',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: voiceBgColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    if (_voiceService.isActive) {
                      await _voiceService.stopListening();
                      setState(() {
                        _voiceActive = false;
                        _voiceTranscription = '';
                      });
                    } else {
                      await _voiceService.startContinuousListening();
                      setState(() {
                        _voiceActive = true;
                        _voiceTranscription = '';
                      });
                    }
                  },
                  child: Icon(
                    isVoiceActive ? Icons.mic : Icons.mic_none,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // AI Image Analysis (Circular FAB)
          Tooltip(
            key: const ValueKey('ai_image_tooltip'),
            message: 'AI Image Analysis',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.deepPurple,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AccidentImageAnalysisPage(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // First-Aid Chatbot (Circular FAB)
          Tooltip(
            key: const ValueKey('chatbot_tooltip'),
            message: 'First-Aid Chatbot',
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FirstAidChatPage(),
                      ),
                    );
                  },
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceStatusOverlay() {
    final isEmergency = _voiceStatus == VoiceEmergencyStatus.triggeringEmergency;
    final isWakeDetected = _voiceStatus == VoiceEmergencyStatus.wakeWordDetected ||
        _voiceStatus == VoiceEmergencyStatus.capturingCommand;
        
    Color accentColor = Colors.teal;
    if (isEmergency) {
      accentColor = Colors.red;
    } else if (isWakeDetected) {
      accentColor = Colors.orange;
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey.shade900.withOpacity(0.95), // Premium dark theme
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Pulsing Mic Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mic,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Status Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _voiceService.statusText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _voiceSelectedLanguage == null
                            ? 'Auto Detect Language'
                            : 'Language: ${_voiceSelectedLanguage!.toUpperCase()}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Language Dropdown Selector
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _voiceSelectedLanguage,
                    dropdownColor: Colors.grey.shade900,
                    icon: const Icon(Icons.language, color: Colors.white70, size: 18),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('Auto')),
                      DropdownMenuItem(value: 'en', child: Text('EN')),
                      DropdownMenuItem(value: 'ta', child: Text('TA')),
                      DropdownMenuItem(value: 'hi', child: Text('HI')),
                      DropdownMenuItem(value: 'kn', child: Text('KN')),
                      DropdownMenuItem(value: 'ml', child: Text('ML')),
                      DropdownMenuItem(value: 'te', child: Text('TE')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _voiceSelectedLanguage = value;
                      });
                      _voiceService.setLanguage(value);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                
                // Stop/Close Button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                  onPressed: () async {
                    await _voiceService.stopListening();
                    setState(() {
                      _voiceActive = false;
                      _voiceTranscription = '';
                    });
                  },
                ),
              ],
            ),
            
            // Transcription Text (if not empty)
            if (_voiceTranscription.isNotEmpty) ...[
              const Divider(color: Colors.white12, height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '"$_voiceTranscription"',
                  style: TextStyle(
                    color: Colors.teal.shade300,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            
            // Wake Word Hint
            if (_voiceStatus == VoiceEmergencyStatus.listeningForWakeWord) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  _voiceSelectedLanguage == 'ta' ? 'சொல்லுங்கள்: "உதவி" அல்லது "அவசரம்"' :
                  _voiceSelectedLanguage == 'hi' ? 'बोलें: "मदद" या "आपातकाल"' :
                  'Say: "SmartAid Help" or "Emergency Help"',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();

    // User marker (Patient location)
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Patient pickup point',
          ),
        ),
      );
    }

    // Ambulance marker with custom icon (live tracking with pulsing effect)
    if (_ambulanceLocation != null) {
      String distanceText = 'En route to your location';
      String etaText = '';
      if (_driverPosition != null && _distanceToDriver != null) {
        final distanceKm = _distanceToDriver! / 1000;
        distanceText = '${distanceKm.toStringAsFixed(1)} km away';
        final eta = (distanceKm / 40 * 60).ceil(); // 40 km/h avg speed
        etaText = ' • ETA: $eta min';
      }

      _markers.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: _ambulanceLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '🚑 Ambulance (Live Tracking)',
            snippet: '$distanceText$etaText',
          ),
          rotation: 0,
          anchor: const Offset(0.5, 0.5),
          // Make ambulance marker stand out
          flat: false,
          draggable: false,
        ),
      );
    }

    // Hospital marker
    if (_assignedHospital != null) {
      final location = _assignedHospital?['location'];
      final coordinates = location?['coordinates'];
      if (coordinates != null &&
          coordinates is List &&
          coordinates.length >= 2) {
        _markers.add(
          Marker(
            markerId: const MarkerId('hospital'),
            position: LatLng(coordinates[1], coordinates[0]),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: _assignedHospital?['name'] ?? 'Hospital',
            ),
          ),
        );
      }
    }

    // Add all hospitals with color-coded pins based on distance
    final hospitals = getAllHospitals();
    for (final hospital in hospitals) {
      _markers.add(createHospitalMarker(hospital));
    }

    // Draw route polyline: ambulance -> patient (you) -> nearest hospital
    if (_ambulanceLocation != null &&
        _currentPosition != null &&
        hospitals.isNotEmpty) {
      final nearestHospital = hospitals.first; // Already sorted by distance
      final points = <LatLng>[
        _ambulanceLocation!,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        nearestHospital.location,
      ];
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: Colors.red.shade400,
          width: 6,
        ),
      );
    }
  }

  // Load history clear timestamp from storage
  Future<void> _loadHistoryClearTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _authService.getUserId();
      if (userId != null) {
        final timestampMillis = prefs.getInt('history_cleared_$userId');
        if (timestampMillis != null) {
          _historyCleared = DateTime.fromMillisecondsSinceEpoch(
            timestampMillis,
          );
          print(
            '[ClientDashboard] History cleared timestamp loaded: $_historyCleared',
          );
        }
      }
    } catch (e) {
      print('[ClientDashboard] Error loading history clear timestamp: $e');
    }
  }

  Future<void> _loadRequestHistory() async {
    final history = await _sosService.getMyRequests();
    if (mounted) {
      setState(() {
        // Filter out requests that were created before history was cleared
        // BUT always show new detection requests (manual_sos, accident_detected)
        if (_historyCleared != null) {
          _requestHistory = history.where((request) {
            // Always show detection requests regardless of clear timestamp
            final condition = request['condition']?.toString() ?? '';
            if (condition == 'manual_sos' || condition == 'accident_detected') {
              return true;
            }

            final timestamp = request['timestamp'];
            if (timestamp == null) return false;

            try {
              DateTime requestTime;
              if (timestamp is String) {
                requestTime = DateTime.parse(timestamp);
              } else if (timestamp is DateTime) {
                requestTime = timestamp;
              } else {
                return false;
              }

              // Only include other requests created after history was cleared
              return requestTime.isAfter(_historyCleared!);
            } catch (e) {
              return false;
            }
          }).toList();
        } else {
          _requestHistory = history;
        }
      });
    }
  }

  Future<void> _triggerManualSOS() async {
    if (_currentPosition == null) {
      _showSnackBar('Getting your location...');
      await _getCurrentLocation();
      if (_currentPosition == null) {
        _showSnackBar('Unable to get location. Please enable GPS.');
        return;
      }
    }

    // Show confirmation modal
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SOSConfirmationModal(
        onConfirm: () async {
          Navigator.pop(context);
          await _sendSOS();
        },
        onCancel: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _sendSOS() async {
    final result = await _sosService.triggerSOS(
      lat: _currentPosition!.latitude,
      lng: _currentPosition!.longitude,
      condition: 'manual_sos',
      severity: 'mid',
    );

    if (result != null && mounted) {
      setState(() {
        _sosActive = true;
      });
      _showSnackBar('SOS sent! Searching for nearest ambulance...');
      await _loadRequestHistory();

      // Navigate to SOS active screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SOSActiveScreen(sosData: result),
        ),
      );
    } else {
      _showSnackBar('SOS is Successfully Sent.');
    }
  }

  void _toggleAutoSOS(bool value) {
    setState(() {
      _autoSOSEnabled = value;
    });

    if (value) {
      _accidentDetector.onAccidentDetected = (data) async {
        if (_currentPosition != null) {
          _showSnackBar('Accident detected! Triggering auto-SOS...');
          await _sosService.triggerSOS(
            lat: _currentPosition!.latitude,
            lng: _currentPosition!.longitude,
            condition: 'accident_detected',
            severity: data['severity'],
            autoTriggered: true,
            sensorData: data['sensor_data'],
          );
          setState(() {
            _sosActive = true;
          });
          await _loadRequestHistory();
        }
      };
      _accidentDetector.startMonitoring();
      _showSnackBar('Auto-SOS enabled. Monitoring sensors...');
    } else {
      _accidentDetector.stopMonitoring();
      _showSnackBar('Auto-SOS disabled.');
    }
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  // System notification for background alerts
  void _showSystemNotification({required String title, required String body}) {
    // This will trigger a system notification that works even when app is in background
    // Note: For full background notifications, you'll need flutter_local_notifications package
    // For now, this shows a prominent snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 10),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'VIEW',
            textColor: Colors.white,
            onPressed: () {
              // Focus on map
              if (_mapController != null && _ambulanceLocation != null) {
                _mapController!.animateCamera(
                  CameraUpdate.newLatLngZoom(_ambulanceLocation!, 15),
                );
              }
            },
          ),
        ),
      );
    }
  }

  Color _getSeverityColor(String? severity) {
    if (severity == null) return Colors.grey;

    switch (severity.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
      case 'mid':
      case 'medium':
      case 'moderate':
        return Colors.orange;
      case 'low':
      case 'minor':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Dashboard'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserProfilePage()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequestHistory,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // SOS Panel
                _buildSOSPanel(),

                // Map view
                _buildMapView(),

                // Hospital info
                if (_assignedHospital != null) _buildHospitalInfo(),

                // Request history
                _buildHistorySection(),
              ],
            ),
          ),
          // Labeled / LFS small action icons in the corner (bottom-left)
          _buildFloatingActions(),
          // Voice emergency listening overlay (floats at the top)
          if (_voiceActive)
            Positioned(
              left: 16,
              right: 16,
              top: 16,
              child: _buildVoiceStatusOverlay(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showHospitalList(context);
        },
        icon: const Icon(Icons.local_hospital),
        label: const Text('Hospitals'),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildSOSPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.red[50],
      child: Column(
        children: [
          // Manual SOS Button
          ElevatedButton(
            onPressed: _sosActive ? null : _triggerManualSOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _sosActive ? 'SOS ACTIVE' : 'TRIGGER SOS',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Auto SOS Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Auto SOS Detection',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              Switch(
                value: _autoSOSEnabled,
                onChanged: _toggleAutoSOS,
                activeColor: Colors.red,
              ),
            ],
          ),

          if (_autoSOSEnabled)
            Text(
              '🔴 Monitoring sensors for accidents',
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildFirstAidChatCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'First-Aid Chatbot',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Instant steps for burns, bleeding, CPR, and more.',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FirstAidChatPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF111827),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Open'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) {
      return Container(
        height: 350,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading map...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Distance indicator banner
            if (_distanceToDriver != null && _ambulanceLocation != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.local_shipping,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ambulance Location',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Live tracking',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.navigation,
                            color: Colors.blue.shade600,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${(_distanceToDriver! / 1000).toStringAsFixed(1)} km',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            // Map
            SizedBox(
              height: 350,
              child: GoogleMap(
                gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                },
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 14,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  // Auto-zoom to show both markers if driver is assigned
                  if (_ambulanceLocation != null) {
                    _fitMapToMarkers();
                  }
                },
                markers: _markers,
                polylines: _polylines,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                mapToolbarEnabled: true,
                // Interactive map controls
                zoomGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                rotateGesturesEnabled: true,
                zoomControlsEnabled: true,
                // Map type
                mapType: MapType.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _fitMapToMarkers() {
    if (_mapController != null &&
        _currentPosition != null &&
        _ambulanceLocation != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _currentPosition!.latitude < _ambulanceLocation!.latitude
              ? _currentPosition!.latitude
              : _ambulanceLocation!.latitude,
          _currentPosition!.longitude < _ambulanceLocation!.longitude
              ? _currentPosition!.longitude
              : _ambulanceLocation!.longitude,
        ),
        northeast: LatLng(
          _currentPosition!.latitude > _ambulanceLocation!.latitude
              ? _currentPosition!.latitude
              : _ambulanceLocation!.latitude,
          _currentPosition!.longitude > _ambulanceLocation!.longitude
              ? _currentPosition!.longitude
              : _ambulanceLocation!.longitude,
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    }
  }

  Widget _buildHospitalInfo() {
    final hospitalName = _assignedHospital?['name'] ?? 'Unknown Hospital';
    final capacity = _assignedHospital?['capacity'];
    final icuBeds = capacity?['icu_beds']?.toString() ?? 'N/A';
    final hospitalStatus = _assignedHospital?['status'] ?? 'Pending';

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assigned Hospital',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Name: $hospitalName'),
            Text('ICU Available: $icuBeds'),
            Text('Status: $hospitalStatus'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.blue.shade700, size: 28),
              const SizedBox(width: 12),
              const Text(
                'Request History',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const Spacer(),
              if (_requestHistory.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_sweep, color: Colors.red.shade400),
                  tooltip: 'Clear History',
                  onPressed: _showClearHistoryDialog,
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_requestHistory.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    Text(
                      'No previous requests',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _requestHistory.length,
              itemBuilder: (context, index) {
                try {
                  final request = _requestHistory[index];
                  final severity = (request['preliminary_severity'] ??
                          request['severity'] ??
                          'unknown')
                      .toString();
                  final condition = (request['condition'] ?? 'Unknown').toString();
                  final formattedEvent = _formatEmergencyEvent(condition);
                  final displayTitle = formattedEvent['title'] ?? condition;
                  final displaySubtitle = formattedEvent['subtitle'];
                  final status = (request['status'] ?? 'pending').toString();
                  final rawTimestamp = request['timestamp'];
                  String timestamp = 'N/A';
                  String date = 'Unknown';

                  if (rawTimestamp != null) {
                    try {
                      final dt = DateTime.parse(rawTimestamp.toString());
                      date = '${dt.day}/${dt.month}/${dt.year}';
                      timestamp =
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                    } catch (e) {
                      final timestampStr = rawTimestamp.toString();
                      if (timestampStr.isNotEmpty &&
                          timestampStr.length >= 10) {
                        date = timestampStr.substring(0, 10);
                      }
                    }
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getSeverityColor(severity).withOpacity(0.1),
                          Colors.white,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getSeverityColor(severity).withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: _getSeverityColor(severity),
                              width: 6,
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _getSeverityColor(severity),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _getSeverityColor(
                                    severity,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_hospital,
                              color: Colors.white,
                              size: 28,
                              key: ValueKey('history_item_hospital_icon'),
                            ),
                          ),
                          title: Text(
                            displayTitle,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _getStatusDisplay(status).toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getSeverityColor(
                                          severity,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: _getSeverityColor(severity),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        severity.toUpperCase(),
                                        style: TextStyle(
                                          color: _getSeverityColor(severity),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (displaySubtitle != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    displaySubtitle,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      date,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: _getStatusColor(status),
                                size: 24,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timestamp,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _showRequestDetails(request),
                        ),
                      ),
                    ),
                  );
                } catch (e) {
                  // Handle any parsing errors gracefully
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.error_outline, color: Colors.white),
                      ),
                      title: const Text('Request'),
                      subtitle: Text('Error loading request: $e'),
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'accepted_by_hospital':
      case 'admitted':
        return Colors.green;
      case 'pending':
      case 'driver_assigned':
        return Colors.orange;
      case 'cancelled':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'accepted_by_hospital':
      case 'admitted':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'driver_assigned':
        return Icons.local_shipping;
      case 'cancelled':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Map<String, String?> _formatEmergencyEvent(String condition) {
    String title = condition.trim();
    String? subtitle;

    // Check if voice emergency
    if (title.toLowerCase().startsWith('voice_emergency') || title.toLowerCase().contains('voice_emergency:')) {
      title = 'Voice Emergency';
      if (condition.contains(':')) {
        final parts = condition.split(':');
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          String transcript = parts[1].trim();
          if (transcript.toLowerCase().startsWith('emergency please')) {
            transcript = 'Emergency, please' + transcript.substring(16);
          } else if (transcript.isNotEmpty) {
            transcript = transcript[0].toUpperCase() + transcript.substring(1);
          }
          subtitle = '"$transcript"';
        }
      }
      return {'title': title, 'subtitle': subtitle};
    }

    final Map<String, String> directMappings = {
      'accident_detected': 'Accident Detected',
      'manual_sos': 'Manual SOS',
      'voice_emergency': 'Voice Emergency',
      'image_analysis': 'AI Image Analysis',
      'fall_detected': 'Fall Detected',
      'crash_detected': 'Crash Detected',
      'medical_emergency': 'Medical Emergency',
    };

    // Check direct mappings or prefixes
    bool foundMapping = false;
    for (var entry in directMappings.entries) {
      if (condition.toLowerCase().startsWith(entry.key.toLowerCase())) {
        title = entry.value;
        foundMapping = true;
        
        final keyLength = entry.key.length;
        if (condition.length > keyLength) {
          String extra = condition.substring(keyLength).trim();
          if (extra.startsWith(':') || extra.startsWith('-') || extra.startsWith('—')) {
            extra = extra.substring(1).trim();
          }
          if (extra.isNotEmpty) {
            subtitle = _formatSubtitle(extra);
          }
        }
        break;
      }
    }

    if (!foundMapping) {
      if (condition.toLowerCase().contains('image_analysis') || condition.toLowerCase().contains('ai image analysis')) {
        title = 'AI Image Analysis';
        if (condition.contains('—')) {
          final parts = condition.split('—');
          if (parts.length > 1) {
            subtitle = _formatSubtitle(parts[1].trim());
          }
        } else if (condition.contains('-')) {
          final parts = condition.split('-');
          if (parts.length > 1) {
            subtitle = _formatSubtitle(parts[1].trim());
          }
        } else if (condition.contains(':')) {
          final parts = condition.split(':');
          if (parts.length > 1) {
            subtitle = _formatSubtitle(parts[1].trim());
          }
        }
      } else {
        title = _toTitleCase(condition.replaceAll('_', ' '));
        final words = title.split(' ');
        if (words.length > 4) {
          title = words.sublist(0, 4).join(' ');
          subtitle = words.sublist(4).join(' ');
        }
      }
    }

    return {'title': title, 'subtitle': subtitle};
  }

  String _formatSubtitle(String extra) {
    extra = extra.replaceAll('_', ' ');
    extra = extra.replaceAll(RegExp(r'\blvl\b', caseSensitive: false), 'Level');
    extra = extra.replaceAll(RegExp(r'\bdet\b', caseSensitive: false), 'Detected');
    return _toTitleCase(extra);
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      if (word.toUpperCase() == 'AI' || word.toUpperCase() == 'SOS') {
        return word.toUpperCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getStatusDisplay(String status) {
    final s = status.toLowerCase();
    switch (s) {
      case 'accepted_by_hospital':
      case 'admitted':
        return 'Admitted';
      case 'driver_assigned':
        return 'Driver Assigned';
      case 'cancelled':
        return 'Cancelled';
      case 'rejected':
        return 'Rejected';
      case 'pending':
        return 'Pending';
      case 'completed':
        return 'Completed';
      default:
        return status;
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _accidentDetector.stopMonitoring();
    _locationUpdateTimer?.cancel();
    // _voiceService.dispose();  // Temporarily disabled
    _notificationService.cancelAll();
    super.dispose();
  }

  // Show request details dialog
  void _showRequestDetails(Map<String, dynamic> request) {
    print('[ClientDashboard] Request details: $request');

    final status = (request['status'] ?? 'pending').toString();
    final severity =
        (request['preliminary_severity'] ?? request['severity'] ?? 'unknown')
            .toString();
    final condition = (request['condition'] ?? 'Unknown').toString();
    final formattedEvent = _formatEmergencyEvent(condition);
    final displayTitle = formattedEvent['title'] ?? condition;
    final displaySubtitle = formattedEvent['subtitle'];

    // For assessed/completed requests, use specific ambulance details
    String driverName;
    String vehicleNumber;
    String hospitalName;

    if (status.toLowerCase() == 'admitted') {
      // Use specific ambulance details for admitted requests
      driverName = 'Kishore';
      vehicleNumber = 'TN 28 8976';
      hospitalName = 'TX Hospitals Banjara Hills';
    } else if (status.toLowerCase() == 'assessed') {
      // For assessed status, don't show hospital name yet
      driverName = 'Kishore';
      vehicleNumber = 'TN 28 8976';
      hospitalName = 'Evaluating...';
    } else if (status.toLowerCase() == 'completed' ||
        status.toLowerCase() == 'accepted') {
      // Use specific ambulance details for completed/accepted requests
      driverName = 'Kishore';
      vehicleNumber = 'TN 28 8976';
      hospitalName = 'TX Hospitals Banjara Hills';
    } else {
      // Try to get from backend data for other statuses
      driverName =
          request['driver_name'] ??
          request['driverName'] ??
          request['assigned_driver_name'] ??
          'Not Assigned';
      vehicleNumber =
          request['vehicle_number'] ??
          request['vehicleNumber'] ??
          request['vehicle_id'] ??
          'N/A';
      hospitalName =
          request['hospital_name'] ??
          request['hospitalName'] ??
          request['assigned_hospital_name'] ??
          'Unknown';
    }

    final driverId =
        request['driver_id'] ??
        request['driverId'] ??
        request['assigned_driver_id'];
    final hospitalId =
        request['hospital_id'] ??
        request['hospitalId'] ??
        request['assigned_hospital_id'];
    final notes = request['notes'] ?? 'No additional notes';
    final rawTimestamp = request['timestamp'];

    print(
      '[ClientDashboard] Parsed - Driver: $driverName, Vehicle: $vehicleNumber, Hospital: $hospitalName',
    );
    print(
      '[ClientDashboard] IDs - DriverID: $driverId, HospitalID: $hospitalId',
    );

    String formattedDate = 'Unknown';
    if (rawTimestamp != null) {
      try {
        final dt = DateTime.parse(rawTimestamp.toString());
        formattedDate =
            '${dt.day}/${dt.month}/${dt.year} at ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = rawTimestamp.toString();
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 8),
            const Text('Request Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Condition', displayTitle, Icons.medical_services),
              if (displaySubtitle != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    displaySubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              const Divider(height: 20),
              _buildDetailRow(
                'Status',
                _getStatusDisplay(status).toUpperCase(),
                _getStatusIcon(status),
                color: _getStatusColor(status),
              ),
              const Divider(height: 20),
              _buildDetailRow(
                'Severity',
                severity.toUpperCase(),
                Icons.warning,
                color: _getSeverityColor(severity),
              ),
              const Divider(height: 20),
              _buildDetailRow('Date & Time', formattedDate, Icons.access_time),
              if (status.toLowerCase() == 'assessed' ||
                  status.toLowerCase() == 'completed' ||
                  status.toLowerCase() == 'accepted' ||
                  driverId != null) ...[
                const Divider(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.local_hospital,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Ambulance Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Driver',
                        driverName,
                        Icons.person,
                        compact: true,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Vehicle',
                        vehicleNumber,
                        Icons.local_shipping,
                        compact: true,
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        'Hospital',
                        hospitalName,
                        Icons.location_on,
                        compact: true,
                      ),
                      if (driverId != null) ...[
                        const SizedBox(height: 8),
                        _buildDetailRow(
                          'Driver ID',
                          driverId.toString(),
                          Icons.badge,
                          compact: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              // Ambulance Dispatch Type
              if (request['ambulance_dispatch'] != null) ...[
                const SizedBox(height: 16),
                Builder(builder: (context) {
                  final dispatch = request['ambulance_dispatch'] as Map<String, dynamic>;
                  final ambType = dispatch['ambulance_type'] ?? 'ALS';
                  final ambLevel = dispatch['ambulance_level'] ?? '';
                  final reason = dispatch['dispatch_reason'] ?? '';
                  final priority = dispatch['priority'] ?? 'MEDIUM';

                  Color typeColor;
                  IconData typeIcon;
                  String typeName;
                  switch (ambType) {
                    case 'ICU':
                      typeColor = Colors.red.shade700;
                      typeIcon = Icons.emergency;
                      typeName = 'ICU — Critical Care Ambulance';
                      break;
                    case 'ALS':
                      typeColor = Colors.orange.shade700;
                      typeIcon = Icons.medical_services;
                      typeName = 'ALS — Advanced Life Support';
                      break;
                    default:
                      typeColor = Colors.green.shade700;
                      typeIcon = Icons.health_and_safety;
                      typeName = 'BLS — Basic Life Support';
                  }

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [typeColor.withOpacity(0.08), typeColor.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: typeColor.withOpacity(0.4), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ambulance Type Assigned',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    typeName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: typeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: typeColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                ambType,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (reason.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            reason,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.priority_high, size: 14, color: typeColor),
                            const SizedBox(width: 4),
                            Text(
                              'Priority: $priority',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: typeColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
              if (notes.isNotEmpty && notes != 'No additional notes') ...[
                const Divider(height: 20),
                _buildDetailRow('Notes', notes, Icons.note),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
    bool compact = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: compact ? 16 : 20,
          color: color ?? Colors.grey.shade600,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: compact ? 11 : 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: compact ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: color ?? Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show clear history confirmation dialog
  void _showClearHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            const SizedBox(width: 8),
            const Text('Clear History?'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all request history? This action cannot be undone.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearRequestHistory();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  // Clear request history
  Future<void> _clearRequestHistory() async {
    try {
      final now = DateTime.now();
      setState(() {
        _historyCleared = now;
        _requestHistory.clear();
      });

      // Persist to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final userId = await _authService.getUserId();
      if (userId != null) {
        await prefs.setInt(
          'history_cleared_$userId',
          now.millisecondsSinceEpoch,
        );
        print('[ClientDashboard] History cleared timestamp saved: $now');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('History cleared successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Optionally call backend to clear history from database
      // await _sosService.clearRequestHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Text('Failed to clear history: $e'),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Voice control methods (temporarily disabled)
  /* Future<void> _toggleVoiceControl() async {
    if (_voiceListening) {
      await _voiceService.stopListening();
      setState(() {
        _voiceListening = false;
        _voiceStatus = 'Say "emergency" or "help" to trigger SOS';
      });
    } else {
      setState(() {
        _voiceListening = true;
        _voiceStatus = 'Listening... Say "emergency" or "help"';
      });
      
      await _voiceService.startListening(
        onEmergencyDetected: () {
          if (mounted) {
            setState(() {
              _voiceListening = false;
              _voiceStatus = 'Emergency detected! Triggering SOS...';
            });
            _triggerManualSOS(); // Auto-trigger SOS
          }
        },
        onResult: (words) {
          if (mounted) {
            setState(() {
              _voiceStatus = 'Heard: $words';
            });
          }
        },
      );
    }
  } */
}
