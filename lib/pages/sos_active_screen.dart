import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math' show atan2, cos, pi, sin, sqrt;
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../services/socket_service.dart';
import '../services/directions_service.dart';
import '../services/location_service.dart';

enum SOSStatus {
  pending,
  assigned,
  enRoute,
  arrived,
  pickedUp,
  completed,
}

class SOSActiveScreen extends StatefulWidget {
  final Map<String, dynamic> sosData;

  const SOSActiveScreen({Key? key, required this.sosData}) : super(key: key);

  @override
  State<SOSActiveScreen> createState() => _SOSActiveScreenState();
}

class _SOSActiveScreenState extends State<SOSActiveScreen> with TickerProviderStateMixin {
  final SocketService _socketService = SocketService();
  final DirectionsService _directionsService = DirectionsService();
  final LocationService _locationService = LocationService();
  
  GoogleMapController? _mapController;
  SOSStatus _currentStatus = SOSStatus.pending;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  Set<Circle> _circles = {};
  List<LatLng> _routePoints = [];
  
  // Driver tracking data
  Map<String, dynamic>? _driverInfo;
  LatLng? _driverLocation;
  LatLng? _clientLocation;
  String _eta = '1 min';
  String _distance = '0.02 km';
  String _durationText = '1 min';
  String _distanceText = '0.02 km';
  String _driverRating = '4.8';
  
  // Animation
  late AnimationController _pulseController;
  Timer? _etaUpdateTimer;
  Timer? _ambulanceAnimationTimer;
  int _routeAnimationIndex = 0;
  DateTime? _lastDriverUpdate;

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _emergencyRed = Color(0xFFEF4444);
  static const Color _sheetBackground = Color(0xFFF3F4F6);

  @override
  void initState() {
    super.initState();
    _initializeLocations();
    _setupPulseAnimation();
    _setupSocketListeners();
    _updateStatusFromData();
    _startEtaUpdates();
  }

  Future<void> _initializeLocations() async {
    // Client location from SOS data
    final rawClientLat = widget.sosData['location']?['coordinates']?[1] ?? widget.sosData['lat'];
    final rawClientLng = widget.sosData['location']?['coordinates']?[0] ?? widget.sosData['lng'];

    double? clientLat = (rawClientLat as num?)?.toDouble();
    double? clientLng = (rawClientLng as num?)?.toDouble();

    if (!_isValidCoordinates(clientLat, clientLng)) {
      final current = await _locationService.getCurrentLocation();
      if (current != null) {
        clientLat = current.latitude;
        clientLng = current.longitude;
      }
    }

    _clientLocation = LatLng(
      clientLat ?? 13.1111713,
      clientLng ?? 77.6029145,
    );
    
    // Check if driver info exists
    if (widget.sosData['driver'] != null) {
      _driverInfo = widget.sosData['driver'];
      final driverLat = (_driverInfo!['location']?['coordinates']?[1] as num?)?.toDouble() ??
          (_driverInfo!['lat'] as num?)?.toDouble();
      final driverLng = (_driverInfo!['location']?['coordinates']?[0] as num?)?.toDouble() ??
          (_driverInfo!['lng'] as num?)?.toDouble();

      if (_isValidCoordinates(driverLat, driverLng)) {
        _driverLocation = LatLng(driverLat!, driverLng!);
      }

      final rating = _driverInfo!['rating']?.toString();
      if (rating != null && rating.isNotEmpty) {
        _driverRating = rating;
      }
    }

    _setupMarkers();

    _animateCameraToShowBoth();

    if (_driverLocation != null && _clientLocation != null) {
      _refreshRouteAndMetrics();
    }
  }

  bool _isValidCoordinates(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (lat.abs() > 90 || lng.abs() > 180) return false;
    if (lat == 0 && lng == 0) return false;
    return true;
  }

  void _setupPulseAnimation() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )
      ..addListener(_updatePulseCircle)
      ..repeat();
  }

  void _updatePulseCircle() {
    if (_clientLocation == null) return;
    final radius = 35 + (_pulseController.value * 60);

    _circles = {
      Circle(
        circleId: const CircleId('client_pulse'),
        center: _clientLocation!,
        radius: radius,
        fillColor: _primaryBlue.withOpacity(0.12 - (_pulseController.value * 0.06)),
        strokeColor: _primaryBlue.withOpacity(0.3),
        strokeWidth: 1,
      ),
      Circle(
        circleId: const CircleId('client_core'),
        center: _clientLocation!,
        radius: 12,
        fillColor: _primaryBlue.withOpacity(0.9),
        strokeColor: Colors.white,
        strokeWidth: 3,
      ),
    };

    if (mounted) {
      setState(() {});
    }
  }

  void _setupSocketListeners() {
    // Listen for driver location updates
    _socketService.socket?.on('driver_location_update', (data) {
      print('[SOSActive] 📍 Driver location update: $data');
      if (mounted && data != null) {
        _handleDriverLocationUpdate(data);
      }
    });

    // Listen for driver accepted
    _socketService.socket?.on('driver_accepted', (data) {
      print('[SOSActive] ✅ Driver accepted: $data');
      if (mounted) {
        _handleDriverAccepted(data);
      }
    });

    // Listen for request assigned
    _socketService.socket?.on('request_assigned', (data) {
      print('[SOSActive] 🚑 Request assigned: $data');
      if (mounted) {
        _handleDriverAccepted(data);
      }
    });

    // Listen for driver arrived
    _socketService.socket?.on('driver_arrived', (data) {
      print('[SOSActive] 🏁 Driver arrived: $data');
      if (mounted) {
        setState(() {
          _currentStatus = SOSStatus.arrived;
          _eta = 'Arrived';
          _distance = '0 m';
        });
      }
    });
    
    // Listen for picked up
    _socketService.socket?.on('picked_up', (data) {
      print('[SOSActive] 🚗 Picked up: $data');
      if (mounted) {
        setState(() {
          _currentStatus = SOSStatus.pickedUp;
        });
      }
    });
  }

  void _handleDriverAccepted(dynamic data) {
    setState(() {
      _currentStatus = SOSStatus.assigned;
      _driverInfo = {
        'name': data['driver_name'] ?? 'Driver',
        'vehicle': data['vehicle'] ?? 'Ambulance',
        'contact': data['contact'] ?? data['driver_contact'] ?? '',
        'eta': data['eta_minutes'] ?? '--',
      };
      _driverRating = (data['rating'] ?? data['driver_rating'] ?? _driverRating).toString();
      _eta = '${data['eta_minutes'] ?? '--'} min';
      
      if (data['lat'] != null && data['lng'] != null) {
        _driverLocation = LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );
        _setupMarkers();
        _createRouteLine();
        _animateCameraToAssignment();
      }
    });
  }

  void _handleDriverLocationUpdate(dynamic data) {
    final lat = data['lat'] ?? data['latitude'] ?? data['location']?['lat'];
    final lng = data['lng'] ?? data['longitude'] ?? data['location']?['lng'];
    
    if (lat != null && lng != null) {
      final newLocation = LatLng((lat as num).toDouble(), (lng as num).toDouble());
 
      _lastDriverUpdate = DateTime.now();
      _stopAmbulanceAnimation();
      
      final etaVal = data['eta'] ?? data['eta_minutes'];
      final distanceVal = data['distance'] ?? data['distance_km'];

      setState(() {
        _driverLocation = newLocation;
        if (_currentStatus == SOSStatus.assigned) {
          _currentStatus = SOSStatus.enRoute;
        }
        
        if (etaVal != null) {
          _eta = '$etaVal min';
          _durationText = _eta;
        }
        if (distanceVal != null) {
          _distanceText = '${(distanceVal as num).toDouble().toStringAsFixed(1)} km';
          _distance = _distanceText;
        }
        
        _setupMarkers();
      });
 
      // If we didn't receive eta/distance from server, fetch route & compute them locally
      if (etaVal == null || distanceVal == null) {
        _refreshRouteAndMetrics();
      } else {
        // Just update route points for map polyline rendering
        _directionsService.getRoutePolyline(
          origin: _driverLocation!,
          destination: _clientLocation!,
        ).then((routePoints) {
          if (mounted) {
            setState(() {
              _routePoints = routePoints;
              _polylines
                ..clear()
                ..add(
                  Polyline(
                    polylineId: const PolylineId('route'),
                    points: routePoints,
                    color: _primaryBlue,
                    width: 6,
                  ),
                );
            });
          }
        });
      }
      
      // Animate camera to follow ambulance
      _animateCameraToDriver();
    }
  }

  void _updateStatusFromData() {
    final status = widget.sosData['status']?.toString().toLowerCase() ?? 'pending';
    
    setState(() {
      if (status == 'pending') {
        _currentStatus = SOSStatus.pending;
      } else if (status == 'accepted' || status == 'assigned') {
        _currentStatus = SOSStatus.assigned;
        _extractDriverInfo();
        _animateCameraToAssignment();
      } else if (status == 'enroute' || status == 'en_route') {
        _currentStatus = SOSStatus.enRoute;
        _extractDriverInfo();
      } else if (status == 'arrived') {
        _currentStatus = SOSStatus.arrived;
        _extractDriverInfo();
      } else if (status == 'picked_up' || status == 'in_transit') {
        _currentStatus = SOSStatus.pickedUp;
        _extractDriverInfo();
      }
    });
    
    if (_driverLocation != null && _clientLocation != null) {
      _refreshRouteAndMetrics();
    }
  }

  void _extractDriverInfo() {
    if (widget.sosData['driver_name'] != null || widget.sosData['driver'] != null) {
      _driverInfo = {
        'name': widget.sosData['driver_name'] ?? widget.sosData['driver']?['name'] ?? 'Driver',
        'vehicle': widget.sosData['vehicle'] ?? widget.sosData['driver']?['vehicle'] ?? 'Ambulance',
        'contact': widget.sosData['driver_contact'] ?? widget.sosData['driver']?['contact'] ?? '',
      };
    }
    
    // Try to get driver location
    if (widget.sosData['driver_current_location'] != null) {
      final loc = widget.sosData['driver_current_location'];
      _driverLocation = LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    }
  }

  void _setupMarkers() {
    _markers.clear();
    
    // Client marker
    if (_clientLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('client'),
          position: _clientLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    // Ambulance marker
    if (_driverLocation != null && _currentStatus != SOSStatus.pending) {
      _markers.add(
        Marker(
          markerId: const MarkerId('ambulance'),
          position: _driverLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '🚑 ${_driverInfo?['name'] ?? 'Ambulance'}',
            snippet: 'ETA: $_eta',
          ),
          anchor: const Offset(0.5, 0.5),
          rotation: _calculateBearing(),
        ),
      );
    }
    
    if (mounted) setState(() {});
  }

  double _calculateBearing() {
    if (_driverLocation == null || _clientLocation == null) return 0;
    
    final lat1 = _driverLocation!.latitude * pi / 180;
    final lat2 = _clientLocation!.latitude * pi / 180;
    final dLng = (_clientLocation!.longitude - _driverLocation!.longitude) * pi / 180;
    
    final y = sin(dLng) * cos(lat2);
    final x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLng);
    
    return atan2(y, x) * 180 / pi;
  }

  void _createRouteLine() {
    _refreshRouteAndMetrics();
  }

  Future<void> _refreshRouteAndMetrics() async {
    if (_driverLocation == null || _clientLocation == null) return;

    final routePoints = await _directionsService.getRoutePolyline(
      origin: _driverLocation!,
      destination: _clientLocation!,
    );

    final matrix = await _directionsService.getDistanceMatrix(
      origin: _driverLocation!,
      destination: _clientLocation!,
    );

    if (!mounted) return;

    setState(() {
      _routePoints = routePoints;
      _routeAnimationIndex = 0;
      _polylines
        ..clear()
        ..add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: _primaryBlue,
            width: 6,
          ),
        );

      if (matrix != null) {
        _distanceText = matrix['distanceText']?.toString() ?? _distanceText;
        _durationText = matrix['durationText']?.toString() ?? _durationText;
        _distance = _distanceText;
        _eta = _durationText;
      } else {
        _updateFallbackEtaDistance();
      }
    });

    _startAmbulanceAnimation();
  }

  void _updateFallbackEtaDistance() {
    if (_driverLocation == null || _clientLocation == null) return;

    const earthRadius = 6371.0; // km
    final lat1 = _driverLocation!.latitude * pi / 180;
    final lat2 = _clientLocation!.latitude * pi / 180;
    final dLat = (lat2 - lat1);
    final dLng = (_clientLocation!.longitude - _driverLocation!.longitude) * pi / 180;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final distance = earthRadius * c; // in km

    if (distance < 1) {
      _distance = '${(distance * 1000).toInt()} m';
    } else {
      _distance = '${distance.toStringAsFixed(1)} km';
    }

    final etaMinutes = (distance / 40 * 60).ceil();
    _eta = '$etaMinutes min';
    _distanceText = _distance;
    _durationText = _eta;
  }

  void _startEtaUpdates() {
    _etaUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_currentStatus == SOSStatus.enRoute) {
        _refreshRouteAndMetrics();
      }
    });
  }

  void _animateCameraToShowBoth() {
    if (_mapController == null || _clientLocation == null) return;
    
    if (_driverLocation != null) {
      final bounds = LatLngBounds(
        southwest: LatLng(
          _driverLocation!.latitude < _clientLocation!.latitude 
              ? _driverLocation!.latitude : _clientLocation!.latitude,
          _driverLocation!.longitude < _clientLocation!.longitude 
              ? _driverLocation!.longitude : _clientLocation!.longitude,
        ),
        northeast: LatLng(
          _driverLocation!.latitude > _clientLocation!.latitude 
              ? _driverLocation!.latitude : _clientLocation!.latitude,
          _driverLocation!.longitude > _clientLocation!.longitude 
              ? _driverLocation!.longitude : _clientLocation!.longitude,
        ),
      );
      
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100),
      );
    } else {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_clientLocation!, 15),
      );
    }
  }

  void _animateCameraToAssignment() {
    if (_mapController == null || _clientLocation == null) return;

    _animateCameraToShowBoth();

    if (_driverLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverLocation!, 16.5),
      );
    }
  }

  void _animateCameraToDriver() {
    if (_mapController == null || _driverLocation == null) return;
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLng(_driverLocation!),
    );
  }

  bool _shouldUseLiveDriverUpdates() {
    if (_lastDriverUpdate == null) return false;
    return DateTime.now().difference(_lastDriverUpdate!).inSeconds < 10;
  }

  void _startAmbulanceAnimation() {
    if (_routePoints.length < 2) return;
    if (_shouldUseLiveDriverUpdates()) return;

    _ambulanceAnimationTimer?.cancel();
    _routeAnimationIndex = 0;

    _ambulanceAnimationTimer = Timer.periodic(
      const Duration(milliseconds: 900),
      (timer) {
        if (_routePoints.isEmpty) {
          timer.cancel();
          return;
        }
        if (_shouldUseLiveDriverUpdates()) {
          timer.cancel();
          return;
        }

        final nextIndex = (_routeAnimationIndex + 1).clamp(0, _routePoints.length - 1);
        final nextPoint = _routePoints[nextIndex];

        setState(() {
          _driverLocation = nextPoint;
          _setupMarkers();
        });

        if (nextIndex % 4 == 0) {
          _animateCameraToDriver();
        }

        if (nextIndex >= _routePoints.length - 1) {
          timer.cancel();
        } else {
          _routeAnimationIndex = nextIndex;
        }
      },
    );
  }

  void _stopAmbulanceAnimation() {
    _ambulanceAnimationTimer?.cancel();
  }

  void _callDriver() {
    final phone = _driverInfo?['contact'] ?? '';
    if (phone.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calling $phone...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver contact not available')),
      );
    }
  }

  void _cancelSOS() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel SOS?'),
        content: const Text('Are you sure you want to cancel the emergency request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      Navigator.pop(context, 'cancelled');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _etaUpdateTimer?.cancel();
    _ambulanceAnimationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
            },
            initialCameraPosition: CameraPosition(
              target: _clientLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
            circles: _circles,
            onMapCreated: (controller) {
              _mapController = controller;
              _animateCameraToShowBoth();
            },
            mapType: MapType.satellite,
            myLocationEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: false,
            trafficEnabled: true,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildStatusPill(),
              ),
            ),
          ),

          Positioned(
            right: 16,
            bottom: 220,
            child: FloatingActionButton(
              heroTag: 'sos-emergency',
              backgroundColor: _emergencyRed,
              onPressed: _cancelSOS,
              child: const Icon(Icons.emergency, color: Colors.white),
            ),
          ),

          _buildBottomSheet(),
        ],
      ),
    );
  }

  Widget _buildStatusPill() {
    final statusText = _statusHeadline();
    final subline = _statusSubline();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 360),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.82),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _primaryBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: _currentStatus == SOSStatus.pending
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(_primaryBlue),
                        ),
                      )
                    : const Icon(Icons.local_hospital, color: _primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subline,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusHeadline() {
    switch (_currentStatus) {
      case SOSStatus.pending:
        return 'Searching for nearby ambulances...';
      case SOSStatus.assigned:
        return 'Ambulance assigned';
      case SOSStatus.enRoute:
        return 'Ambulance en route';
      case SOSStatus.arrived:
        return 'Ambulance arrived';
      case SOSStatus.pickedUp:
        return 'On the way to hospital';
      case SOSStatus.completed:
        return 'Trip completed';
    }
  }

  String _statusSubline() {
    if (_currentStatus == SOSStatus.pending) {
      return 'Locating the closest driver to your location';
    }
    if (_eta != '--') {
      return 'ETA $_eta • $_distanceText';
    }
    return 'Tracking live location updates';
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.24,
      maxChildSize: 0.52,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: _sheetBackground.withOpacity(0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_currentStatus == SOSStatus.pending)
                _buildWaitingSection()
              else
                _buildDriverInfoSection(),
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWaitingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Finding nearest ambulance',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Hold tight while we connect you with the closest driver.',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInfoChip('Live tracking', Icons.radar, _primaryBlue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoChip('Priority dispatch', Icons.flash_on, _emergencyRed),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverInfoSection() {
    String statusString = "On the way";
    if (_currentStatus == SOSStatus.arrived) {
      statusString = "Arrived";
    } else if (_currentStatus == SOSStatus.pickedUp) {
      statusString = "On the way to hospital";
    } else if (_currentStatus == SOSStatus.completed) {
      statusString = "Completed";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ambulance Assigned',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            children: [
              _buildDetailRowItem(Icons.person_outline, 'Driver', _driverInfo?['name'] ?? 'Rajesh Kumar'),
              const Divider(height: 20, thickness: 0.8),
              _buildDetailRowItem(Icons.directions_car_outlined, 'Vehicle', _driverInfo?['vehicle'] ?? 'Ambulance'),
              const Divider(height: 20, thickness: 0.8),
              _buildDetailRowItem(Icons.access_time, 'ETA', _eta),
              const Divider(height: 20, thickness: 0.8),
              _buildDetailRowItem(Icons.straighten, 'Distance', _distanceText),
              const Divider(height: 20, thickness: 0.8),
              _buildDetailRowItem(Icons.info_outline, 'Status', statusString, statusColor: _primaryBlue),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Route Info',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 10),
        _buildRouteLegendRow(_primaryBlue, 'From driver location'),
        const SizedBox(height: 6),
        _buildRouteLegendRow(_emergencyRed, 'To your location'),
      ],
    );
  }

  Widget _buildDetailRowItem(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.dmSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: statusColor ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, bool highlight) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: highlight ? _primaryBlue : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: highlight ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: highlight ? Colors.white : AppTheme.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: AppTheme.textDark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteLegendRow(Color dotColor, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 13,
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final hasDriverContact = (_driverInfo?['contact']?.toString().trim().isNotEmpty ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: hasDriverContact ? _callDriver : null,
              icon: const Icon(Icons.call),
              label: const Text('Call Driver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: OutlinedButton.icon(
              onPressed: _cancelSOS,
              icon: const Icon(Icons.close),
              label: const Text('Cancel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _emergencyRed,
                side: const BorderSide(color: _emergencyRed),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
