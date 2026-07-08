import 'package:cloud_firestore/cloud_firestore.dart';

enum DeviceStatus { healthy, warning, critical }

class Device {
  final String id;
  final String name;
  final String model;
  final String mac;
  final String firmwareCurrent;
  final String firmwareLatest;
  final DateTime? releaseDate;
  final DateTime? eolDate;
  final double healthScore;
  final DeviceStatus status;
  final DateTime? lastSeen;

  Device({
    required this.id,
    required this.name,
    required this.model,
    required this.mac,
    required this.firmwareCurrent,
    required this.firmwareLatest,
    this.releaseDate,
    this.eolDate,
    required this.healthScore,
    required this.status,
    this.lastSeen,
  });

  /// Factory constructor to parse Firestore document snapshot.
  factory Device.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Safely parse timestamps
    final releaseDate = data['release_date'] is Timestamp
        ? (data['release_date'] as Timestamp).toDate()
        : null;
    final eolDate = data['eol_date'] is Timestamp
        ? (data['eol_date'] as Timestamp).toDate()
        : null;
    final lastSeen = data['last_seen'] is Timestamp
        ? (data['last_seen'] as Timestamp).toDate()
        : null;

    final name = data['name']?.toString() ?? 'Unknown Device';
    final model = data['model']?.toString() ?? 'Generic Model';
    final mac = data['mac']?.toString() ?? '00:00:00:00:00:00';
    final firmwareCurrent = data['firmware_current']?.toString() ?? '1.0.0';
    final firmwareLatest = data['firmware_latest']?.toString() ?? '1.0.0';
    final healthScore = (data['health_score'] as num?)?.toDouble() ?? 0.0;

    // Evaluate computed status ("Check Engine Light" logic)
    final evaluatedStatus = _calculateStatus(
      healthScore: healthScore,
      firmwareCurrent: firmwareCurrent,
      firmwareLatest: firmwareLatest,
      eolDate: eolDate,
    );

    return Device(
      id: doc.id,
      name: name,
      model: model,
      mac: mac,
      firmwareCurrent: firmwareCurrent,
      firmwareLatest: firmwareLatest,
      releaseDate: releaseDate,
      eolDate: eolDate,
      healthScore: healthScore,
      status: evaluatedStatus,
      lastSeen: lastSeen,
    );
  }

  /// Converts Device data to Firestore Map format.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'model': model,
      'mac': mac,
      'firmware_current': firmwareCurrent,
      'firmware_latest': firmwareLatest,
      if (releaseDate != null) 'release_date': Timestamp.fromDate(releaseDate!),
      if (eolDate != null) 'eol_date': Timestamp.fromDate(eolDate!),
      'health_score': healthScore,
      'status': status.name.toUpperCase(), // Store as HEALTHY, WARNING, CRITICAL
      'last_seen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : FieldValue.serverTimestamp(),
    };
  }

  /// Static helper to calculate status based on policy rules
  static DeviceStatus _calculateStatus({
    required double healthScore,
    required String firmwareCurrent,
    required String firmwareLatest,
    DateTime? eolDate,
  }) {
    final now = DateTime.now();

    // 1. CRITICAL RULES:
    // - EOL date has already passed
    // - Health score is very low (under 40)
    if (eolDate != null && eolDate.isBefore(now)) {
      return DeviceStatus.critical;
    }
    if (healthScore < 40.0) {
      return DeviceStatus.critical;
    }

    // 2. WARNING RULES (Check Engine conditions):
    // - Outdated firmware (current doesn't match latest)
    // - EOL date is approaching in less than 6 months (approx 180 days)
    if (firmwareCurrent.trim() != firmwareLatest.trim()) {
      return DeviceStatus.warning;
    }
    if (eolDate != null) {
      final daysToEol = eolDate.difference(now).inDays;
      if (daysToEol >= 0 && daysToEol < 180) {
        return DeviceStatus.warning;
      }
    }

    // 3. Otherwise, everything is silent and healthy
    return DeviceStatus.healthy;
  }

  /// Helper to get user-friendly status text
  String get statusText {
    switch (status) {
      case DeviceStatus.critical:
        return 'Critical';
      case DeviceStatus.warning:
        return 'Warning';
      case DeviceStatus.healthy:
        return 'Healthy';
    }
  }
}
