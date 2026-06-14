import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../config/api_config.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/auth_service.dart';
import '../services/hospital_service.dart';
import '../services/socket_service.dart';
import '../services/emergency_alert_service.dart';
import '../config/app_theme.dart';
import 'hospital_profile_page.dart';
import 'patient_request_details_dialog.dart';
import 'dart:async';
import 'dart:math' show atan2, cos, pi, sin, sqrt;

class AdminDashboardEnhanced extends StatefulWidget {
  const AdminDashboardEnhanced({Key? key}) : super(key: key);

  @override
  State<AdminDashboardEnhanced> createState() => _AdminDashboardEnhancedState();
}

class _AdminDashboardEnhancedState extends State<AdminDashboardEnhanced> {
  final _authService = AuthService();
  final _hospitalService = HospitalService();
  final _socketService = SocketService();
  final _emergencyAlert = EmergencyAlertService();

  GoogleMapController? _mapController;
  
  // Capacity management
  int _icuBeds = 3;
  int _generalBeds = 12;
  int _doctorsAvailable = 4;

  // Patient requests
  List<Map<String, dynamic>> _incomingPatients = [];
  List<Map<String, dynamic>> _admissionHistory = [];

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  
  // Emergency alert banner state
  String? _lastEmergencyText;
  Color? _lastEmergencyColor;

  @override
  void initState() {
    super.initState();
    _emergencyAlert.initialize();
    _loadPatientRequests();
    _setupSocketListeners();
  }

  void _setupSocketListeners() {
    final userId = _authService.getUserId();
    userId.then((id) {
      if (id != null) {
        _socketService.connect(
          ApiConfig.baseUrl,
          id,
          'admin',
        );

        // Join admin room reliably — must happen AFTER socket connects
        // The socket service auto-joins 'admins' but backend also emits to 'admin'
        _socketService.socket?.on('connect', (_) {
          _socketService.socket?.emit('join', {'room': 'admin'});
          print('[Admin] ✅ Joined admin room after connect');
        });
        // Also try immediately in case already connected
        if (_socketService.isConnected) {
          _socketService.socket?.emit('join', {'room': 'admin'});
        }

        // Listen for injury assessments
        _socketService.socket?.on('injury_assessment_submitted', (data) {
          print('[Admin] Received injury assessment: $data');
          if (mounted) {
            _handleNewAssessment(data);
          }
        });

        // Listen for incoming patient notifications - IMMEDIATE REFRESH
        _socketService.socket?.on('incoming_patient', (data) {
          print('[Admin] ⚡ URGENT: Incoming patient notification: $data');
          if (mounted) {
            _handleIncomingPatient(data);
            _emergencyAlert.playEmergencyAlert();
            _showIncomingPatientModal(data is Map<String, dynamic> ? data : {});
          }
        });

        // Listen for SOS alerts — show modal for every new emergency
        _socketService.socket?.on('sos_alert', (data) {
          print('[Admin] 🚨 SOS Alert received: $data');
          if (mounted) {
            _loadPatientRequests(); // Refresh immediately
            _emergencyAlert.playEmergencyAlert();
            _showNewSOSModal(data is Map<String, dynamic> ? data : {});
          }
        });

        // Listen for driver acceptance — show modal + refresh
        _socketService.socket?.on('driver_accepted', (data) {
          print('[Admin] ✅ Driver accepted request: $data');
          if (mounted) {
            _handleDriverAcceptedRequest(data);
            _loadPatientRequests(); // Refresh immediately
            _emergencyAlert.playEmergencyAlert();
            _showDriverAcceptedModal(data is Map<String, dynamic> ? data : {});
          }
        });

        // Listen for driver location updates (live ambulance tracking)
        _socketService.socket?.on('driver_location_update', (data) {
          print('[Admin] 📍 Driver location update: $data');
          if (mounted) {
            _handleDriverLocationUpdate(data);
          }
        });
      }
    });
  }

  void _handleDriverLocationUpdate(dynamic data) {
    // Update the driver location in the patient request
    final requestId = data['request_id'];
    if (requestId != null) {
      setState(() {
        final patientIndex = _incomingPatients.indexWhere((p) => p['_id'] == requestId);
        if (patientIndex != -1) {
          _incomingPatients[patientIndex]['driver_location'] = {
            'coordinates': [
              data['longitude'] ?? data['lng'] ?? 0.0,
              data['latitude'] ?? data['lat'] ?? 0.0,
            ],
          };
          _updateMapMarkers(); // Refresh map to show updated ambulance position
        }
      });
    }
  }

  void _handleIncomingPatient(dynamic data) {
    setState(() {
      _loadPatientRequests();
    });
    _showSnackBar(
      '🚑 Patient incoming: ${data['patient_name'] ?? 'Unknown'} — ETA: ${data['eta'] ?? 'Unknown'}',
      backgroundColor: AppTheme.primary,
    );
  }

  /// Modal shown when a patient is dispatched to THIS hospital (after driver accepts)
  void _showIncomingPatientModal(Map<String, dynamic> data) {
    if (!mounted) return;
    final patientName = data['patient_name'] ?? data['user_name'] ?? 'Unknown';
    final eta = data['eta'] ?? data['eta_minutes'];
    final condition = data['condition'] ?? '';
    final severity = (data['preliminary_severity'] ?? '').toString().toUpperCase();
    final dispatch = data['ambulance_dispatch'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.blue[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.local_hospital, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '🚑 PATIENT INCOMING',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'An ambulance is en route to your hospital!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalRow(Icons.person, 'Patient', patientName),
                  if (condition.isNotEmpty) _modalRow(Icons.medical_information, 'Condition', condition),
                  if (severity.isNotEmpty) _modalRow(Icons.warning_amber, 'Severity', severity),
                  if (eta != null) _modalRow(Icons.timer, 'ETA', '$eta min'),
                  if (dispatch != null)
                    _modalRow(
                      Icons.airport_shuttle,
                      'Ambulance',
                      '${dispatch['ambulance_type'] ?? ''} — ${dispatch['ambulance_level'] ?? ''}',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.blue[700], size: 18),
                const SizedBox(width: 6),
                Text('Alert is playing...', style: TextStyle(color: Colors.blue[700], fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emergencyAlert.stopAlert();
              Navigator.pop(ctx);
            },
            child: Text('Dismiss', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Prepare Admission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _emergencyAlert.stopAlert();
              Navigator.pop(ctx);
              _loadPatientRequests();
            },
          ),
        ],
      ),
    );
  }

  /// Modal shown on every new SOS alert broadcast in the area
  void _showNewSOSModal(Map<String, dynamic> data) {
    if (!mounted) return;
    final patientName = data['user_name'] ?? data['patient_name'] ?? 'Unknown';
    final condition = data['condition'] ?? '';
    final severity = (data['preliminary_severity'] ?? '').toString().toUpperCase();
    final dispatch = data['ambulance_dispatch'] as Map<String, dynamic>?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.emergency, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '🚨 NEW SOS REQUEST',
                style: TextStyle(
                  color: Colors.red[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A new emergency request has been received!',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalRow(Icons.person, 'Patient', patientName),
                  if (condition.isNotEmpty) _modalRow(Icons.medical_information, 'Condition', condition),
                  if (severity.isNotEmpty) _modalRow(Icons.warning_amber, 'Severity', severity),
                  if (dispatch != null)
                    _modalRow(
                      Icons.airport_shuttle,
                      'Ambulance Type',
                      '${dispatch['ambulance_type'] ?? ''} — ${dispatch['priority'] ?? ''} priority',
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.volume_up, color: Colors.red[700], size: 18),
                const SizedBox(width: 6),
                Text('Alert is playing...', style: TextStyle(color: Colors.red[700], fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emergencyAlert.stopAlert();
              Navigator.pop(ctx);
            },
            child: Text('Dismiss', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('View Requests'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _emergencyAlert.stopAlert();
              Navigator.pop(ctx);
              _loadPatientRequests();
            },
          ),
        ],
      ),
    );
  }

  Widget _modalRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  void _handleDriverAcceptedRequest(dynamic data) {
    final patientName = data['patient_name'] ?? 'Aswanth';
    final driverName = data['driver_name'] ?? 'Unknown Driver';
    final condition = data['condition'] ?? '';
    final severity = data['preliminary_severity'] ?? '';
    final eta = data['eta_minutes'] ?? 'Unknown';
    
    // Determine alert type based on condition
    String alertMessage;
    Color alertColor;
    
    if (condition == 'accident_detected' || condition.toString().toLowerCase().contains('accident')) {
      alertMessage = '🚨 VEHICLE ACCIDENT: $patientName - Driver $driverName responding - ETA: $eta min';
      alertColor = Colors.red;
    } else if (condition == 'manual_sos') {
      alertMessage = '🆘 SOS EMERGENCY: $patientName - Driver $driverName responding - ETA: $eta min';
      alertColor = Colors.orange;
    } else {
      alertMessage = '🚑 Emergency: $patientName - Driver $driverName - ETA: $eta min';
      alertColor = AppTheme.primary;
    }
    
    setState(() {
      _lastEmergencyText = alertMessage;
      _lastEmergencyColor = alertColor;
    });

    _showSnackBar(
      alertMessage,
      backgroundColor: alertColor,
    );
  }

  /// Modal shown when a driver accepts a request — hospital needs to prepare
  void _showDriverAcceptedModal(Map<String, dynamic> data) {
    if (!mounted) return;
    final patientName = data['patient_name'] ?? data['user_name'] ?? 'Unknown';
    final driverName = data['driver_name'] ?? 'Unknown Driver';
    final condition = data['condition'] ?? '';
    final severity = (data['preliminary_severity'] ?? '').toString().toUpperCase();
    final eta = data['eta_minutes'] ?? data['eta'];
    final vehicle = data['vehicle'] ?? 'Ambulance';
    final driverContact = data['driver_contact'] ?? '';
    final patientContact = data['patient_contact'] ?? '';
    final bloodGroup = data['blood_group'] ?? '';

    final isAccident = condition == 'accident_detected' || condition.toString().toLowerCase().contains('accident');
    final headerColor = isAccident ? Colors.red : Colors.green;
    final headerText = isAccident ? '🚨 ACCIDENT — DRIVER RESPONDING' : '✅ DRIVER ACCEPTED REQUEST';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: headerColor.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: headerColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(isAccident ? Icons.car_crash : Icons.check_circle, color: headerColor, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                headerText,
                style: TextStyle(
                  color: headerColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A driver has accepted the emergency request. Prepare for patient arrival.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800]),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: headerColor.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _modalRow(Icons.person, 'Patient', patientName),
                  if (patientContact.isNotEmpty) _modalRow(Icons.phone, 'Patient Contact', patientContact),
                  if (bloodGroup.isNotEmpty) _modalRow(Icons.bloodtype, 'Blood Group', bloodGroup),
                  if (condition.isNotEmpty) _modalRow(Icons.medical_information, 'Condition', condition),
                  if (severity.isNotEmpty) _modalRow(Icons.warning_amber, 'Severity', severity),
                  const Divider(height: 16),
                  _modalRow(Icons.person_pin, 'Driver', driverName),
                  if (driverContact.isNotEmpty) _modalRow(Icons.phone_android, 'Driver Contact', driverContact),
                  _modalRow(Icons.airport_shuttle, 'Vehicle', vehicle),
                  if (eta != null) _modalRow(Icons.timer, 'ETA', '$eta min'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.volume_up, color: headerColor, size: 18),
                const SizedBox(width: 6),
                Text('Alert is playing...', style: TextStyle(color: headerColor, fontStyle: FontStyle.italic, fontSize: 13)),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _emergencyAlert.stopAlert();
              Navigator.pop(ctx);
            },
            child: Text('Dismiss', style: TextStyle(color: Colors.grey[700])),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.local_hospital, size: 18),
            label: const Text('Prepare Admission'),
            style: ElevatedButton.styleFrom(
              backgroundColor: headerColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              _emergencyAlert.stopAlert();
              Navigator.pop(ctx);
              _loadPatientRequests();
            },
          ),
        ],
      ),
    );
  }

  void _handleNewAssessment(dynamic data) {
    setState(() {
      // Update the patient in the list with the assessment
      final requestId = data['request_id'];
      final patientIndex = _incomingPatients.indexWhere((p) => p['_id'] == requestId);
      if (patientIndex != -1) {
        _incomingPatients[patientIndex]['injury_risk'] = data['injury_risk'];
        _incomingPatients[patientIndex]['injury_notes'] = data['injury_notes'];
        _incomingPatients[patientIndex]['assessment_time'] = DateTime.now().toIso8601String();
      }
      // Update banner
      final patientName = data['patient_name'] ?? 'Patient';
      final risk = (data['injury_risk'] ?? '').toString();
      _lastEmergencyText = 'Emergency alert: $patientName — ${risk.toUpperCase()} risk';
      _lastEmergencyColor = _getRiskColor(risk);
    });

    _showSnackBar(
      'New injury assessment: ${data['patient_name']} - ${data['injury_risk'].toString().toUpperCase()} risk',
      backgroundColor: _getRiskColor(data['injury_risk']),
    );
  }

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return AppTheme.success;
      case 'medium':
        return AppTheme.warning;
      case 'high':
        return AppTheme.primary;
      default:
        return Colors.grey;
    }
  }

  Future<void> _loadPatientRequests() async {
    try {
      final requests = await _hospitalService.getPatientRequests();
      if (mounted) {
        setState(() {
          // Match backend statuses: accepted, enroute, picked_up, assessed, in_transit
          _incomingPatients = requests.where((r) => 
            r['status'] == 'accepted' || 
            r['status'] == 'enroute' || 
            r['status'] == 'en_route' ||
            r['status'] == 'picked_up' ||
            r['status'] == 'assessed' ||
            r['status'] == 'in_transit'
          ).toList();
          // Sort newest first by timestamp
          _incomingPatients.sort((a, b) {
            final tA = a['timestamp'] ?? '';
            final tB = b['timestamp'] ?? '';
            return tB.toString().compareTo(tA.toString());
          });
          _admissionHistory = requests.where((r) => r['status'] == 'admitted' || r['status'] == 'rejected').toList();
          _admissionHistory.sort((a, b) {
            final tA = a['timestamp'] ?? '';
            final tB = b['timestamp'] ?? '';
            return tB.toString().compareTo(tA.toString());
          });
          _updateMapMarkers();
        });
      }
    } catch (e, stackTrace) {
      print('[AdminDashboard] Error loading requests: $e');
      print('[AdminDashboard] Stack trace: $stackTrace');
      if (mounted) {
        _showSnackBar('Failed to load patient requests: $e', backgroundColor: Colors.red);
      }
    }
  }

  void _updateMapMarkers() {
    _markers.clear();
    _polylines.clear();

    // Lords College reference location
    const lordsLocation = LatLng(17.3293, 78.3514);
    
    _markers.add(Marker(
      markerId: const MarkerId('lords_reference'),
      position: lordsLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      infoWindow: const InfoWindow(
        title: '📍 Lords Institute of Engineering & Technology',
        snippet: 'Reference location for nearest hospitals',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 1. Shadan Hospital — 1.30 km
    _markers.add(Marker(
      markerId: const MarkerId('shadan_hospital'),
      position: const LatLng(17.3177, 78.3527),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: const InfoWindow(
        title: '🏥 Shadan Hospital ⭐ NEAREST #1',
        snippet: '1.30 km • ⭐4.5 • 150 beds • 20 ICU • 50 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 2. Renova Hospitals Langar Houz — 8.79 km
    _markers.add(Marker(
      markerId: const MarkerId('renova_hospital'),
      position: const LatLng(17.3865, 78.4085),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: const InfoWindow(
        title: '🏥 Renova Hospitals Langar Houz',
        snippet: '8.79 km • ⭐4.3 • 100 beds • 15 ICU • 35 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 3. Germanten Hospitals — 9.21 km
    _markers.add(Marker(
      markerId: const MarkerId('germanten_hospital'),
      position: const LatLng(17.3667, 78.4288),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: const InfoWindow(
        title: '🏥 Germanten Hospitals',
        snippet: '9.21 km • ⭐4.6 • 180 beds • 25 ICU • 60 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 4. Continental Hospitals — 9.35 km
    _markers.add(Marker(
      markerId: const MarkerId('continental_hospital'),
      position: const LatLng(17.4129, 78.3418),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: const InfoWindow(
        title: '🏥 Continental Hospitals',
        snippet: '9.35 km • ⭐4.8 • 300 beds • 40 ICU • 110 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 5. Olive Hospital — 9.72 km
    _markers.add(Marker(
      markerId: const MarkerId('olive_hospital'),
      position: const LatLng(17.3690, 78.4330),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      infoWindow: const InfoWindow(
        title: '🏥 Olive Hospital',
        snippet: '9.72 km • ⭐4.4 • 120 beds • 18 ICU • 45 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 6. Premier Hospital — 10.44 km
    _markers.add(Marker(
      markerId: const MarkerId('premier_hospital'),
      position: const LatLng(17.3610, 78.4440),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(
        title: '🏥 Premier Hospital',
        snippet: '10.44 km • ⭐4.5 • 130 beds • 20 ICU • 50 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 7. CARE Hospitals Banjara Hills — 12.97 km
    _markers.add(Marker(
      markerId: const MarkerId('care_hospital'),
      position: const LatLng(17.4147, 78.4347),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(
        title: '🏥 CARE Hospitals Banjara Hills',
        snippet: '12.97 km • ⭐4.7 • 250 beds • 35 ICU • 90 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 8. TX Hospitals Banjara Hills — 13.19 km
    _markers.add(Marker(
      markerId: const MarkerId('tx_hospital'),
      position: const LatLng(17.4077701, 78.4446554),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(
        title: '🏥 TX Hospitals Banjara Hills',
        snippet: '13.19 km • ⭐4.5 • 160 beds • 22 ICU • 55 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 9. Star Hospitals - Block A & C — 13.51 km
    _markers.add(Marker(
      markerId: const MarkerId('star_hospital'),
      position: const LatLng(17.4178, 78.4386),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(
        title: '🏥 Star Hospitals - Block A & C',
        snippet: '13.51 km • ⭐4.6 • 220 beds • 30 ICU • 80 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // 10. Aster Prime Hospital — 15.82 km
    _markers.add(Marker(
      markerId: const MarkerId('aster_hospital'),
      position: const LatLng(17.4372, 78.4486),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(
        title: '🏥 Aster Prime Hospital',
        snippet: '15.82 km • ⭐4.6 • 200 beds • 28 ICU • 75 doctors',
      ),
      anchor: const Offset(0.5, 0.5),
    ));

    // Add patient markers
    for (var patient in _incomingPatients) {
      final location = patient['location'];
      if (location != null) {
        double lat, lng;
        
        // Handle both formats: {lat: x, lng: y} and {coordinates: [lng, lat]}
        if (location is Map && location.containsKey('lat') && location.containsKey('lng')) {
          lat = (location['lat'] is num) ? (location['lat'] as num).toDouble() : 0.0;
          lng = (location['lng'] is num) ? (location['lng'] as num).toDouble() : 0.0;
        } else if (location is Map && location.containsKey('coordinates')) {
          final coords = location['coordinates'];
          if (coords is List && coords.length >= 2) {
            lng = (coords[0] is num) ? (coords[0] as num).toDouble() : 0.0;
            lat = (coords[1] is num) ? (coords[1] as num).toDouble() : 0.0;
          } else {
            continue; // Skip invalid location
          }
        } else {
          continue; // Skip invalid location
        }
        
        if (lat != 0.0 || lng != 0.0) {
          final riskLevel = patient['injury_risk'] ?? patient['severity'] ?? 'medium';
          final driverInfo = patient['driver_info'];
          final hasDriver = driverInfo != null;
          
          // Patient location marker
          _markers.add(Marker(
            markerId: MarkerId(patient['_id'] ?? 'unknown'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getSeverityColor(riskLevel) == Colors.red
                  ? BitmapDescriptor.hueRed
                  : BitmapDescriptor.hueOrange,
            ),
            infoWindow: InfoWindow(
              title: '🤕 Patient: ${patient['user_name'] ?? 'Arun'} - $riskLevel risk',
              snippet: patient['injury_notes'] ?? patient['condition'] ?? 'No details',
            ),
          ));
          
          // If driver is assigned, add ambulance marker with live tracking
          if (hasDriver && patient['driver_location'] != null) {
            final driverLoc = patient['driver_location'];
            double driverLat = 0.0, driverLng = 0.0;
            
            if (driverLoc is Map && driverLoc.containsKey('coordinates')) {
              final driverCoords = driverLoc['coordinates'];
              if (driverCoords is List && driverCoords.length >= 2) {
                driverLng = (driverCoords[0] is num) ? (driverCoords[0] as num).toDouble() : 0.0;
                driverLat = (driverCoords[1] is num) ? (driverCoords[1] as num).toDouble() : 0.0;
              }
            }
            
            if (driverLat != 0.0 || driverLng != 0.0) {
              // Use nearest hospital (Shadan Hospital) for distance calculation
              const nearestHospitalLat = 17.3177;
              const nearestHospitalLng = 78.3527;
              
              // Calculate distance and ETA from ambulance to hospital
              final distanceKm = _calculateDistance(driverLat, driverLng, nearestHospitalLat, nearestHospitalLng);
              final eta = _calculateETA(distanceKm);
              
              _markers.add(Marker(
                markerId: MarkerId('ambulance_${patient['_id']}'),
                position: LatLng(driverLat, driverLng),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
                infoWindow: InfoWindow(
                  title: '🚑 Ambulance (Live)',
                  snippet: 'Distance: ${distanceKm.toStringAsFixed(1)} km | ETA: $eta',
                ),
                anchor: const Offset(0.5, 0.5),
              ));

                // Draw polyline from ambulance -> patient -> Shadan Hospital (Nearest)
                const hospital = LatLng(nearestHospitalLat, nearestHospitalLng);
                final routePoints = <LatLng>[LatLng(driverLat, driverLng), LatLng(lat, lng), hospital];
                _polylines.add(Polyline(
                  polylineId: PolylineId('route_${patient['_id']}'),
                  points: routePoints,
                  color: Colors.red.shade600,
                  width: 5,
                ));
            }
          }
        }
      }
    }
  }

  // Calculate distance using Haversine formula (accounts for Earth's curvature)
  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLng = _degreesToRadians(lng2 - lng1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Calculate ETA based on average ambulance speed (40 km/h in city traffic)
  String _calculateETA(double distanceKm) {
    const avgSpeedKmh = 40.0;
    final timeHours = distanceKm / avgSpeedKmh;
    final timeMinutes = (timeHours * 60).round();
    
    if (timeMinutes < 2) {
      return '< 2 min';
    } else if (timeMinutes < 60) {
      return '$timeMinutes min';
    } else {
      final hours = timeMinutes ~/ 60;
      final minutes = timeMinutes % 60;
      return minutes > 0 ? '$hours hr $minutes min' : '$hours hr';
    }
  }

  Future<void> _updateCapacity() async {
    final success = await _hospitalService.updateCapacity(
      icuBeds: _icuBeds,
      generalBeds: _generalBeds,
      doctorsAvailable: _doctorsAvailable,
    );

    if (success) {
      _showSnackBar('Capacity updated successfully');
    } else {
      _showSnackBar('Failed to update capacity');
    }
  }

  Future<void> _handleAdmissionDecision(
    Map<String, dynamic> patient,
    String action,
  ) async {
    final success = await _hospitalService.confirmAdmission(
      patient['_id'],
      action,
    );

    if (success && mounted) {
      setState(() {
        _incomingPatients.remove(patient);
        _admissionHistory.insert(0, {
          ...patient,
          'status': action == 'accept' ? 'admitted' : 'rejected',
        });
      });
      _showSnackBar(action == 'accept'
          ? 'Patient admission confirmed'
          : 'Patient admission rejected');
      await _loadPatientRequests();
    } else {
      _showSnackBar('Failed to process decision');
    }
  }

  void _showUpdateCapacityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Hospital Capacity'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Expanded(child: Text('ICU Beds:')),
                  IconButton(
                    onPressed: () =>
                        setDialogState(() => _icuBeds = (_icuBeds - 1).clamp(0, 100)),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_icuBeds'),
                  IconButton(
                    onPressed: () =>
                        setDialogState(() => _icuBeds = (_icuBeds + 1).clamp(0, 100)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text('General Beds:')),
                  IconButton(
                    onPressed: () => setDialogState(
                        () => _generalBeds = (_generalBeds - 1).clamp(0, 100)),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_generalBeds'),
                  IconButton(
                    onPressed: () => setDialogState(
                        () => _generalBeds = (_generalBeds + 1).clamp(0, 100)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              Row(
                children: [
                  const Expanded(child: Text('Doctors Available:')),
                  IconButton(
                    onPressed: () => setDialogState(
                        () => _doctorsAvailable = (_doctorsAvailable - 1).clamp(0, 50)),
                    icon: const Icon(Icons.remove),
                  ),
                  Text('$_doctorsAvailable'),
                  IconButton(
                    onPressed: () => setDialogState(
                        () => _doctorsAvailable = (_doctorsAvailable + 1).clamp(0, 50)),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateCapacity();
              setState(() {});
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {Color? backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'mid':
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HospitalProfilePage()),
              );
            },
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatientRequests,
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Emergency banner
            _buildEmergencyBanner(),
            // Capacity section
            _buildCapacitySection(),
            
            // Map view
            _buildMapView(),
            
            // Incoming patients
            _buildIncomingPatients(),
            
            // History
            _buildHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyBanner() {
    final activeCount = _incomingPatients.length;
    if (activeCount == 0 && _lastEmergencyText == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_lastEmergencyColor ?? Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (_lastEmergencyColor ?? Colors.red).withOpacity(0.6)),
      ),
      child: Row(
        children: [
          Icon(Icons.emergency, color: _lastEmergencyColor ?? Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lastEmergencyText ?? 'Emergency alerts: $activeCount active',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_lastEmergencyText != null)
                  const SizedBox(height: 4),
                Text(
                  'Incoming patients: $activeCount',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: () {
              setState(() {
                _lastEmergencyText = null;
                _lastEmergencyColor = null;
              });
            },
            icon: const Icon(Icons.close),
          )
        ],
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hospital Capacity',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showUpdateCapacityDialog,
                  icon: const Icon(Icons.edit),
                  label: const Text('Update'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCapacityCard('ICU Beds', _icuBeds, Icons.local_hospital),
                _buildCapacityCard('General Beds', _generalBeds, Icons.bed),
                _buildCapacityCard('Doctors', _doctorsAvailable, Icons.person),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacityCard(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.green),
        const SizedBox(height: 8),
        Text(
          '$count',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMapView() {
    return SizedBox(
      height: 300,
      child: GoogleMap(
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
        },
        initialCameraPosition: const CameraPosition(
          target: LatLng(17.4077701, 78.4446554), // TX Hospitals Banjara Hills, Hyderabad
          zoom: 13,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          // Move camera to TX Hospitals Banjara Hills area on load
          controller.animateCamera(
            CameraUpdate.newLatLngZoom(
              const LatLng(17.4077701, 78.4446554), // TX Hospitals Banjara Hills, Hyderabad
              14,
            ),
          );
        },
        markers: _markers,
        polylines: _polylines,
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }

  Widget _buildIncomingPatients() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Incoming Patient Requests',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_incomingPatients.length} Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          if (_incomingPatients.isEmpty)
            Center(
              child: Container(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No incoming patients',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Patient requests will appear here',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
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
              itemCount: _incomingPatients.length,
              itemBuilder: (context, index) {
                final patient = _incomingPatients[index];
                final hasAssessment = patient['injury_risk'] != null && patient['injury_risk'] != '';
                final riskLevel = patient['injury_risk'] ?? patient['severity'] ?? 'medium';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showPatientDetails(patient),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getRiskColor(riskLevel).withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row
                            Row(
                              children: [
                                // Risk Badge
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _getRiskColor(riskLevel),
                                        _getRiskColor(riskLevel).withOpacity(0.7),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _getRiskColor(riskLevel).withOpacity(0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getRiskIcon(riskLevel),
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        hasAssessment ? 'RISK' : 'SOS',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Patient Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              patient['user_name'] ?? 'Arun',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.textDark,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _getRiskColor(riskLevel),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              riskLevel.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.medical_services, size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              patient['condition'] ?? 'Emergency',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(patient['status']),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _getStatusText(patient['status'] ?? 'unknown'),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            
                            // Driver Info
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.local_shipping, color: Colors.orange, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getDriverName(patient),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(Icons.directions_car, size: 12, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text(
                                              _getVehicleDisplayForPatient(patient),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.phone, color: Colors.green),
                                    onPressed: () {
                                      final contact = _getDriverContact(patient);
                                      _showSnackBar('Call: $contact');
                                    },
                                    tooltip: 'Call Driver',
                                  ),
                                ],
                              ),
                            ),
                            
                            // Ambulance Dispatch Info
                            if (patient['ambulance_dispatch'] != null) ...[
                              const SizedBox(height: 12),
                              Builder(builder: (context) {
                                final dispatch = patient['ambulance_dispatch'] as Map<String, dynamic>;
                                final level = dispatch['ambulance_level'] ?? 'BLS';
                                final type = dispatch['ambulance_type'] ?? 'Basic Life Support';
                                final reason = dispatch['dispatch_reason'] ?? '';
                                final priority = dispatch['priority'] ?? 1;
                                final Color dColor;
                                final IconData dIcon;
                                switch (level) {
                                  case 'ICU':
                                    dColor = Colors.red.shade700;
                                    dIcon = Icons.emergency;
                                    break;
                                  case 'ALS':
                                    dColor = Colors.orange.shade700;
                                    dIcon = Icons.medical_services;
                                    break;
                                  default:
                                    dColor = Colors.green.shade700;
                                    dIcon = Icons.local_hospital;
                                }
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [dColor.withOpacity(0.1), dColor.withOpacity(0.03)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: dColor.withOpacity(0.4), width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: dColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(dIcon, color: dColor, size: 20),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Dispatch: $level — $type',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: dColor,
                                              ),
                                            ),
                                            if (reason.toString().isNotEmpty)
                                              Text(
                                                reason.toString(),
                                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: dColor,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          'P$priority',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],

                            // Assessment Notes (if available)
                            if (hasAssessment && patient['injury_notes'] != null && patient['injury_notes'] != '') ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _getRiskColor(riskLevel).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getRiskColor(riskLevel).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.note_alt_outlined,
                                      size: 18,
                                      color: _getRiskColor(riskLevel),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Driver Assessment',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: _getRiskColor(riskLevel),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            patient['injury_notes'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 16),
                            
                            // Action Buttons
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleAdmissionDecision(patient, 'accept'),
                                    icon: const Icon(Icons.check_circle, size: 20),
                                    label: const Text('Accept Admission'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleAdmissionDecision(patient, 'reject'),
                                    icon: const Icon(Icons.cancel, size: 20),
                                    label: const Text('Decline'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red, width: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  IconData _getRiskIcon(String risk) {
    switch (risk.toLowerCase()) {
      case 'low':
        return Icons.healing;
      case 'medium':
        return Icons.warning_amber;
      case 'high':
        return Icons.emergency;
      default:
        return Icons.medical_services;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'accepted':
      case 'enroute':
      case 'en_route':
        return Colors.blue;
      case 'picked_up':
        return Colors.orange;
      case 'assessed':
        return Colors.purple;
      case 'in_transit':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return 'ACCEPTED';
      case 'enroute':
      case 'en_route':
        return 'EN ROUTE';
      case 'picked_up':
        return 'PICKED UP';
      case 'assessed':
        return 'ASSESSED';
      case 'in_transit':
        return 'IN TRANSIT';
      default:
        return status.toUpperCase();
    }
  }

  void _showPatientDetails(Map<String, dynamic> patient) {
    showDialog(
      context: context,
      builder: (context) => PatientRequestDetailsDialog(
        patient: patient,
        onAction: (action) {
          if (action == 'accept') {
            _handleAdmissionDecision(patient, 'accept');
          }
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admission History',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_admissionHistory.isEmpty)
            const Text('No history yet')
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _admissionHistory.length.clamp(0, 5),
              itemBuilder: (context, index) {
                final record = _admissionHistory[index];
                return Card(
                  child: ListTile(
                    leading: Icon(
                      record['status'] == 'admitted'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: record['status'] == 'admitted'
                          ? Colors.green
                          : Colors.red,
                    ),
                    title: Text(record['condition'] ?? 'Unknown'),
                    subtitle: Text(
                      'Status: ${record['status']} | Severity: ${record['severity']}',
                    ),
                    trailing: Text(
                      record['timestamp']?.substring(0, 10) ?? '',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // Helper method to extract vehicle display string
  String _getVehicleDisplay(dynamic vehicle) {
    if (vehicle == null) return 'Ambulance';
    if (vehicle is String) return vehicle;
    if (vehicle is Map) {
      // Handle {type: 'ambulance', plate: 'AMB-001', model: 'Mercedes'}
      final type = vehicle['type'] ?? '';
      final plate = vehicle['plate'] ?? '';
      final model = vehicle['model'] ?? '';
      
      if (plate.isNotEmpty) return plate;
      if (model.isNotEmpty) return model;
      if (type.isNotEmpty) return type;
    }
    return 'Ambulance';
  }

  // Get driver name with hardcoded value for assessed requests
  String _getDriverName(Map<String, dynamic> patient) {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    if (status == 'assessed' || status == 'completed' || status == 'accepted') {
      return 'Kishore';
    }
    return patient['driver_name'] ?? 'Unknown Driver';
  }

  // Get driver contact with hardcoded value for assessed requests
  String _getDriverContact(Map<String, dynamic> patient) {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    if (status == 'assessed' || status == 'completed' || status == 'accepted') {
      return '9492633000';
    }
    return patient['driver_contact'] ?? 'N/A';
  }

  // Get vehicle display with hardcoded value for assessed requests
  String _getVehicleDisplayForPatient(Map<String, dynamic> patient) {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    if (status == 'assessed' || status == 'completed' || status == 'accepted') {
      return 'Kishore Ambulance';
    }
    return _getVehicleDisplay(patient['vehicle']);
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
