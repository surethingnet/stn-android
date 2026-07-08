import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cache keys
  static const String _kCachedDeviceCount = 'stn_cached_device_count';
  static const String _kCachedNetworkStatus = 'stn_cached_network_status';

  // Constructor
  FirebaseService() {
    // Configure Firestore settings for local offline persistence
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  /// Exposes the current Firebase user stream
  Stream<User?> get userStream => _auth.authStateChanges();

  /// Returns the currently signed-in user, if any
  User? get currentUser => _auth.currentUser;

  /// Signs in anonymously to Firebase
  Future<UserCredential?> signInAnonymously() async {
    try {
      final credential = await _auth.signInAnonymously();
      return credential;
    } catch (e) {
      print('Firebase Anonymous Auth Error: $e');
      return null;
    }
  }

  /// Signs out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Streams the list of devices from the Firestore 'inventory' collection in real-time.
  /// Automatically updates the local shared_preferences cache with the latest device state info.
  Stream<List<Device>> getDevicesStream() {
    return _db
        .collection('inventory')
        .orderBy('last_seen', descending: true)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => Device.fromFirestore(doc)).toList();
      _cacheLatestNetworkState(list);
      return list;
    });
  }

  /// Adds a new device to the Firestore 'inventory' collection.
  /// If offline, Firestore caches this write and pushes it to the cloud when a connection is restored.
  Future<void> addDevice(String name, String model, String mac) async {
    final now = DateTime.now();
    
    // Create new device document data with default mock fields for network audit
    final Map<String, dynamic> deviceData = {
      'name': name,
      'model': model,
      'mac': mac,
      'firmware_current': '1.0.1',
      'firmware_latest': '1.0.5', // Simulate slightly outdated to trigger warning
      'release_date': Timestamp.fromDate(now.subtract(const Duration(days: 365 * 2))),
      'eol_date': Timestamp.fromDate(now.add(const Duration(days: 365))), // EOL in 1 year
      'health_score': 85.0, // Default healthy score
      'status': 'WARNING', // Computed as Warning because firmware_current != firmware_latest
      'last_seen': FieldValue.serverTimestamp(),
    };

    await _db.collection('inventory').add(deviceData);
  }

  /// Private helper to save high-level state in SharedPreferences for offline resilience
  Future<void> _cacheLatestNetworkState(List<Device> devices) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kCachedDeviceCount, devices.length);

      // Determine overall network safety status for visual offline fallback
      final hasCritical = devices.any((d) => d.status == DeviceStatus.critical);
      final hasWarning = devices.any((d) => d.status == DeviceStatus.warning);
      String status = 'Healthy';
      if (hasCritical) {
        status = 'Critical';
      } else if (hasWarning) {
        status = 'Warning';
      }
      await prefs.setString(_kCachedNetworkStatus, status);
    } catch (e) {
      print('Shared Preferences caching failed: $e');
    }
  }

  /// Gets cached state for quick, synchronous startup display before Firestore stream resolves
  Future<Map<String, dynamic>> getCachedNetworkState() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_kCachedDeviceCount) ?? 0;
    final status = prefs.getString(_kCachedNetworkStatus) ?? 'Unknown';
    return {
      'deviceCount': count,
      'networkStatus': status,
    };
  }
}
