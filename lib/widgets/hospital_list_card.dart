import 'package:flutter/material.dart';
import '../models/hospital_data.dart';

/// Widget to display hospital information in a card format
class HospitalListCard extends StatelessWidget {
  final HospitalData hospital;
  final VoidCallback? onTap;

  const HospitalListCard({Key? key, required this.hospital, this.onTap})
    : super(key: key);

  Color _getDistanceColor() {
    if (hospital.distanceFromReference < 2.0) {
      return Colors.green;
    } else if (hospital.distanceFromReference < 3.0) {
      return Colors.yellow.shade700;
    } else if (hospital.distanceFromReference < 4.0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  IconData _getDistanceIcon() {
    if (hospital.distanceFromReference < 2.0) {
      return Icons.near_me;
    } else if (hospital.distanceFromReference < 3.0) {
      return Icons.location_on;
    } else {
      return Icons.location_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceColor = _getDistanceColor();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: distanceColor, width: 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hospital name and distance badge
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hospital.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: distanceColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getDistanceIcon(), size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          '${hospital.distanceFromReference.toStringAsFixed(2)} km',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Hospital stats row
              Row(
                children: [
                  // Rating
                  _buildStatChip(
                    icon: Icons.star,
                    label: hospital.rating.toString(),
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 8),

                  // Beds
                  _buildStatChip(
                    icon: Icons.bed,
                    label: '${hospital.bedCount} beds',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),

                  // ICU
                  _buildStatChip(
                    icon: Icons.local_hospital,
                    label: '${hospital.icuCount} ICU',
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Doctors row
              Row(
                children: [
                  _buildStatChip(
                    icon: Icons.medical_services,
                    label: '${hospital.doctorCount} doctors',
                    color: Colors.green,
                  ),
                  const Spacer(),

                  // Distance category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: distanceColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: distanceColor, width: 1),
                    ),
                    child: Text(
                      hospital.distanceCategory,
                      style: TextStyle(
                        color: distanceColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to show list of all hospitals
class HospitalListBottomSheet extends StatelessWidget {
  const HospitalListBottomSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hospitals = getAllHospitals();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.local_hospital, color: Colors.red, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Nearby Hospitals',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem('Very Close', Colors.green, '< 2km'),
                _buildLegendItem('Close', Colors.yellow.shade700, '2-3km'),
                _buildLegendItem('Moderate', Colors.orange, '3-4km'),
                _buildLegendItem('Far', Colors.red, '> 4km'),
              ],
            ),
          ),

          const Divider(height: 1),

          // Hospital list
          Expanded(
            child: ListView.builder(
              itemCount: hospitals.length,
              itemBuilder: (context, index) {
                final hospital = hospitals[index];
                return HospitalListCard(
                  hospital: hospital,
                  onTap: () {
                    // Close the bottom sheet
                    Navigator.pop(context);
                    // Could navigate to map focused on this hospital
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String range) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(range, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }
}

/// Function to show hospital list bottom sheet
void showHospitalList(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => const HospitalListBottomSheet(),
    ),
  );
}
