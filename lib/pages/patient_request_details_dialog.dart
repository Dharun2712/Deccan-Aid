import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PatientRequestDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> patient;
  final Function(String action)? onAction;

  const PatientRequestDetailsDialog({
    Key? key,
    required this.patient,
    this.onAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final riskLevel = patient['injury_risk'] ?? patient['severity'] ?? 'medium';
    final hasDriver = _hasDriverInfo();

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
                  colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.7)],
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
                    child: const Icon(Icons.emergency, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Emergency Request',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Complete Details',
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
                    // Risk Level Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getRiskColor(riskLevel).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRiskColor(riskLevel),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, 
                            color: _getRiskColor(riskLevel), 
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Injury Assessment',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black54,
                                ),
                              ),
                              Text(
                                riskLevel.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getRiskColor(riskLevel),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Patient Profile Section
                    _buildSectionHeader(Icons.person, 'Patient Information'),
                    const SizedBox(height: 12),
                    _buildProfileCard(
                      name: patient['user_name'] ?? 'Arun',
                      subtitle: 'Patient',
                      icon: Icons.person,
                      color: Colors.blue,
                      details: [
                        _ProfileDetail('Name', patient['user_name'] ?? 'Arun', Icons.badge),
                        _ProfileDetail('Age', '20 years', Icons.calendar_today),
                        _ProfileDetail('Blood Group', 'O+ve', Icons.bloodtype),
                        _ProfileDetail('Contact', '9492613200', Icons.phone),
                        _ProfileDetail('Emergency Contact', '9876543212', Icons.phone_in_talk),
                        _ProfileDetail('Blood Donor No', '8769045980', Icons.water_drop),
                        _ProfileDetail('Email', 'msarunsanjeev@gmail.com', Icons.email),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Driver Profile Section (if assigned)
                    if (hasDriver) ...[
                      _buildSectionHeader(Icons.local_shipping, 'Driver Information'),
                      const SizedBox(height: 12),
                      _buildProfileCard(
                        name: _getDriverName(),
                        subtitle: 'Ambulance Driver',
                        icon: Icons.drive_eta,
                        color: Colors.orange,
                        details: [
                          _ProfileDetail('Driver ID', 'DRV-307', Icons.badge),
                          _ProfileDetail('Name', _getDriverName(), Icons.person),
                          _ProfileDetail('Contact', _getDriverContact(), Icons.phone),
                          _ProfileDetail('Vehicle', _getVehicleDisplay(), Icons.local_shipping),
                          _ProfileDetail('License', 'TN-38-DL-2024', Icons.credit_card),
                          _ProfileDetail('Experience', '8 years', Icons.work),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Emergency Details Section
                    _buildSectionHeader(Icons.medical_services, 'Emergency Details'),
                    const SizedBox(height: 12),
                    _buildInfoCard([
                      _InfoRow('Condition', patient['condition'] ?? 'Vehicle Accident', Icons.medical_services),
                      _InfoRow('Status', patient['status'] ?? 'Pending', Icons.info),
                      if (patient['injury_notes'] != null && patient['injury_notes'] != '')
                        _InfoRow('Notes', patient['injury_notes'], Icons.note),
                      _InfoRow('Timestamp', _formatTimestamp(patient['timestamp']), Icons.access_time),
                    ]),

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
                        onAction?.call('accept');
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Accept Patient'),
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
        Icon(icon, color: AppTheme.primary, size: 24),
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

  Widget _buildProfileCard({
    required String name,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<_ProfileDetail> details,
  }) {
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
      child: Column(
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Profile Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: details.map((detail) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(detail.icon, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              detail.value,
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
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(List<_InfoRow> rows) {
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
        children: rows.map((row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(row.icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        row.label,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        row.value,
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
        }).toList(),
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = patient['location'];
    double? lat, lng;
    
    if (location is Map && location.containsKey('lat') && location.containsKey('lng')) {
      lat = (location['lat'] is num) ? (location['lat'] as num).toDouble() : null;
      lng = (location['lng'] is num) ? (location['lng'] as num).toDouble() : null;
    } else if (location is Map && location.containsKey('coordinates')) {
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

  Color _getRiskColor(String risk) {
    switch (risk.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.red;
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

  bool _hasDriverInfo() {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    return status == 'assessed' || status == 'completed' || status == 'accepted';
  }

  bool _hasLocation() {
    final location = patient['location'];
    if (location is Map) {
      if (location.containsKey('lat') && location.containsKey('lng')) {
        return true;
      }
      if (location.containsKey('coordinates') && location['coordinates'] is List) {
        return (location['coordinates'] as List).length >= 2;
      }
    }
    return false;
  }

  String _getDriverName() {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    if (status == 'assessed' || status == 'completed' || status == 'accepted') {
      return 'Kishore';
    }
    return patient['driver_name'] ?? 'Unknown Driver';
  }

  String _getDriverContact() {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    if (status == 'assessed' || status == 'completed' || status == 'accepted') {
      return '9492633000';
    }
    return patient['driver_contact'] ?? 'N/A';
  }

  String _getVehicleDisplay() {
    final status = (patient['status'] ?? '').toString().toLowerCase();
    if (status == 'assessed' || status == 'completed' || status == 'accepted') {
      return 'TN-38-AB-1234';
    }
    return patient['vehicle'] ?? 'N/A';
  }

  String _formatTimestamp(dynamic timestamp) {
    return '2 min ago';
  }
}

class _ProfileDetail {
  final String label;
  final String value;
  final IconData icon;

  _ProfileDetail(this.label, this.value, this.icon);
}

class _InfoRow {
  final String label;
  final String value;
  final IconData icon;

  _InfoRow(this.label, this.value, this.icon);
}
