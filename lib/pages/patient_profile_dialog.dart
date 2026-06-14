import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/sos_service.dart';

class PatientProfileDialog extends StatefulWidget {
  final Map<String, dynamic> patient;
  final Function(String action)? onAction;

  const PatientProfileDialog({
    Key? key,
    required this.patient,
    this.onAction,
  }) : super(key: key);

  @override
  State<PatientProfileDialog> createState() => _PatientProfileDialogState();
}

class _PatientProfileDialogState extends State<PatientProfileDialog> {
  final _sosService = SOSService();
  Uint8List? _imageBytes;
  bool _loadingImage = false;
  bool _imageError = false;

  Map<String, dynamic> get patient => widget.patient;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  bool get _shouldShowImage =>
      patient['has_image'] == true ||
      patient['accident_analysis'] != null ||
      _imageBytes != null;

  Future<void> _loadImage() async {
    final requestId = patient['_id']?.toString() ?? patient['request_id']?.toString();
    // Try loading if has_image flag is set, or if accident_analysis exists
    // (since analysis implies an image was uploaded)
    if (requestId == null) return;
    if (patient['has_image'] != true && patient['accident_analysis'] == null) return;

    setState(() => _loadingImage = true);
    try {
      final base64Str = await _sosService.getRequestImage(requestId);
      if (base64Str != null && base64Str.isNotEmpty && mounted) {
        setState(() {
          _imageBytes = base64Decode(base64Str);
          _loadingImage = false;
        });
      } else if (mounted) {
        setState(() {
          _loadingImage = false;
          _imageError = patient['has_image'] == true; // only error if flag said it existed
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingImage = false;
          _imageError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = patient['severity'] ?? 'medium';
    final condition = patient['condition'] ?? 'Emergency';

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patient Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Emergency Details',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Severity Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getSeverityColor(severity).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getSeverityColor(severity),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, 
                            color: _getSeverityColor(severity), 
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Severity Level',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getSeverityColor(severity),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Accident Image Section
                    if (_shouldShowImage) ...[
                      _buildSectionHeader(Icons.camera_alt, 'Accident Scene Image'),
                      const SizedBox(height: 12),
                      _buildAccidentImageCard(),
                      const SizedBox(height: 24),
                    ],

                    // AI Analysis Section
                    if (patient['accident_analysis'] != null) ...[
                      _buildSectionHeader(Icons.analytics, 'AI Accident Analysis'),
                      const SizedBox(height: 12),
                      _buildAIAnalysisCard(Map<String, dynamic>.from(patient['accident_analysis'] as Map)),
                      const SizedBox(height: 24),
                    ],

                    // Patient Profile Card
                    _buildSectionHeader(Icons.person, 'Patient Information'),
                    const SizedBox(height: 12),
                    _buildProfileCard(),

                    const SizedBox(height: 24),

                    // Emergency Details
                    _buildSectionHeader(Icons.medical_services, 'Emergency Details'),
                    const SizedBox(height: 12),
                    _buildEmergencyCard(condition),

                    const SizedBox(height: 24),

                    // Location Section
                    if (_hasLocation()) ...[
                      _buildSectionHeader(Icons.location_on, 'Location'),
                      const SizedBox(height: 12),
                      _buildLocationCard(),
                    ],
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onAction?.call('accept');
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept Request'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAccidentImageCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _loadingImage
            ? Container(
                height: 200,
                color: Colors.grey.shade100,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading accident image...',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            : _imageError
                ? Container(
                    height: 120,
                    color: Colors.red.shade50,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image, color: Colors.red, size: 32),
                          SizedBox(height: 8),
                          Text('Failed to load image',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  )
                : _imageBytes != null
                    ? Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showFullScreenImage(context),
                            child: Stack(
                              children: [
                                Image.memory(
                                  _imageBytes!,
                                  width: double.infinity,
                                  height: 220,
                                  fit: BoxFit.cover,
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.fullscreen, color: Colors.white, size: 16),
                                        SizedBox(width: 4),
                                        Text('View Full', style: TextStyle(color: Colors.white, fontSize: 11)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            color: Colors.red.shade50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.zoom_in,
                                    size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap image to view full screen',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Container(
                        height: 120,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: Text('Image not available',
                              style: TextStyle(color: Colors.grey)),
                        ),
                      ),
      ),
    );
  }

  Widget _buildAIAnalysisCard(Map<String, dynamic> analysis) {
    final people = analysis['people_detected'] ?? 0;
    final vehicles = analysis['vehicles_detected'] ?? 0;
    final injured = analysis['possible_injured'] ?? 0;
    final fire = analysis['fire_detected'] == true;
    final damageLevel = analysis['damage_level'] ?? 0;
    final severity = '${analysis['severity_level'] ?? 'UNKNOWN'}'.toUpperCase();
    final priority = '${analysis['ambulance_priority'] ?? 'UNKNOWN'}'.toUpperCase();

    final damageLevelText = switch (damageLevel) {
      1 => 'Very Minor',
      2 => 'Minor',
      3 => 'Moderate',
      4 => 'Severe',
      5 => 'Catastrophic',
      _ => 'Unknown',
    };

    final severityColor = severity == 'CRITICAL'
        ? Colors.red
        : severity == 'MEDIUM'
            ? Colors.orange
            : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity & Priority banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: severityColor, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  severity == 'CRITICAL'
                      ? Icons.warning_rounded
                      : severity == 'MEDIUM'
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                  color: severityColor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Severity: $severity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                      Text(
                        'Ambulance Priority: $priority',
                        style: TextStyle(
                          fontSize: 13,
                          color: severityColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stats grid
          Row(
            children: [
              Expanded(child: _analysisStatTile(Icons.people, '$people', 'People', Colors.blue)),
              const SizedBox(width: 8),
              Expanded(child: _analysisStatTile(Icons.directions_car, '$vehicles', 'Vehicles', Colors.indigo)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _analysisStatTile(Icons.personal_injury, '$injured', 'Injured', Colors.red)),
              const SizedBox(width: 8),
              Expanded(child: _analysisStatTile(
                fire ? Icons.local_fire_department : Icons.check_circle,
                fire ? 'YES' : 'No',
                'Fire',
                fire ? Colors.deepOrange : Colors.green,
              )),
            ],
          ),
          const SizedBox(height: 12),

          // Damage level bar
          Row(
            children: [
              const Icon(Icons.car_crash, size: 20, color: Colors.black54),
              const SizedBox(width: 8),
              const Text('Damage Level: ', style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                '$damageLevel/5 — $damageLevelText',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: damageLevel >= 4 ? Colors.red : damageLevel >= 3 ? Colors.orange : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: damageLevel / 5.0,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                damageLevel >= 4 ? Colors.red : damageLevel >= 3 ? Colors.orange : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _analysisStatTile(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    if (_imageBytes == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.memory(_imageBytes!, fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final name = patient['user_name'] ?? 'Unknown';
    final contact = patient['user_contact'] ?? 'N/A';
    final bloodGroup = patient['blood_group'] ?? 'Unknown';
    final hasAllergies = patient['has_medical_allergies'] == true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.person, color: Colors.blue.shade700, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Text(
                      'Patient',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 12),
          // Profile Details
          _buildDetailRow('Name', name, Icons.badge),
          _buildDetailRow('Blood Group', bloodGroup, Icons.bloodtype),
          _buildDetailRow('Contact', contact, Icons.phone),
          _buildDetailRow('Allergies', hasAllergies ? 'Yes — Has Medical Allergies' : 'None reported', Icons.health_and_safety),
        ],
      ),
    );
  }

  Widget _buildEmergencyCard(String condition) {
    final timestamp = patient['timestamp'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow('Condition', condition, Icons.medical_services),
          _buildDetailRow('Status', patient['status'] ?? 'Active', Icons.info),
          _buildDetailRow('Timestamp', _formatTimestamp(timestamp), Icons.access_time),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = patient['location'];
    double? lat, lng;
    
    if (location is Map && location.containsKey('coordinates')) {
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        lng = (coords[0] is num) ? (coords[0] as num).toDouble() : null;
        lat = (coords[1] is num) ? (coords[1] as num).toDouble() : null;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[400], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Emergency Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (lat != null && lng != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.place, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(String severity) {
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
        return Colors.yellow[700]!;
      default:
        return Colors.orange;
    }
  }

  bool _hasLocation() {
    final location = patient['location'];
    if (location is Map && location.containsKey('coordinates')) {
      final coords = location['coordinates'];
      return coords is List && coords.length >= 2;
    }
    return false;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      return '${diff.inDays} days ago';
    } catch (e) {
      return 'Recently';
    }
  }
}
