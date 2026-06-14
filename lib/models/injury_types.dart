// Shared types for the SOS system

enum InjuryRiskLevel { low, medium, high }

// Ambulance dispatch levels
enum AmbulanceLevel { bls, als, icu }

class AmbulanceDispatch {
  final String severityLevel;   // LOW | MEDIUM | CRITICAL
  final String ambulanceLevel;  // LEVEL_1_BLS | LEVEL_2_ALS | LEVEL_3_ICU
  final String ambulanceType;   // BLS | ALS | ICU
  final String dispatchReason;
  final String priority;        // LOW | MEDIUM | HIGH

  AmbulanceDispatch({
    required this.severityLevel,
    required this.ambulanceLevel,
    required this.ambulanceType,
    required this.dispatchReason,
    required this.priority,
  });

  factory AmbulanceDispatch.fromJson(Map<String, dynamic> json) {
    return AmbulanceDispatch(
      severityLevel: json['severity_level'] ?? 'MEDIUM',
      ambulanceLevel: json['ambulance_level'] ?? 'LEVEL_2_ALS',
      ambulanceType: json['ambulance_type'] ?? 'ALS',
      dispatchReason: json['dispatch_reason'] ?? '',
      priority: json['priority'] ?? 'MEDIUM',
    );
  }

  Map<String, dynamic> toJson() => {
    'severity_level': severityLevel,
    'ambulance_level': ambulanceLevel,
    'ambulance_type': ambulanceType,
    'dispatch_reason': dispatchReason,
    'priority': priority,
  };

  String get displayName {
    switch (ambulanceType) {
      case 'BLS': return 'Basic Life Support';
      case 'ALS': return 'Advanced Life Support';
      case 'ICU': return 'Critical Care (ICU)';
      default: return ambulanceType;
    }
  }

  String get shortLabel => ambulanceType; // BLS / ALS / ICU
}
