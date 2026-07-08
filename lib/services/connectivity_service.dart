import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Stream of Wi-Fi connection status. 
  /// Returns `true` if connected to Wi-Fi, `false` otherwise.
  Stream<bool> get isWifiStream {
    return _connectivity.onConnectivityChanged.map((dynamic results) {
      // In connectivity_plus v5.0.0+, it returns List<ConnectivityResult>.
      if (results is List) {
        return results.contains(ConnectivityResult.wifi);
      }
      // Fallback for older versions where it returns a single ConnectivityResult.
      return results == ConnectivityResult.wifi;
    });
  }

  /// Synchronous check if the current network connection is Wi-Fi
  Future<bool> isConnectedToWifi() async {
    final dynamic results = await _connectivity.checkConnectivity();
    if (results is List) {
      return results.contains(ConnectivityResult.wifi);
    }
    return results == ConnectivityResult.wifi;
  }
}
