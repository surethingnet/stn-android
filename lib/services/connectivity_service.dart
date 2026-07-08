import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final NetworkInfo _networkInfo = NetworkInfo();

  /// Stream of Wi-Fi connection status. 
  /// Returns `true` if connected to Wi-Fi, `false` otherwise.
  Stream<bool> get isWifiStream {
    return _connectivity.onConnectivityChanged.map((dynamic results) {
      if (results is List) {
        return results.contains(ConnectivityResult.wifi);
      }
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

  /// Retrieves the current Wi-Fi name (SSID).
  /// Requires Location permission on Android/iOS.
  Future<String?> getWifiName() async {
    if (!await isConnectedToWifi()) {
      return null;
    }

    // Request Location permissions if not already granted
    var status = await Permission.locationWhenInUse.status;
    if (status.isDenied) {
      status = await Permission.locationWhenInUse.request();
    }

    if (status.isGranted) {
      try {
        final wifiName = await _networkInfo.getWifiName();
        // The SSID returned can sometimes be surrounded by double quotes (e.g. '"HomeNetwork"')
        if (wifiName != null) {
          return wifiName.replaceAll('"', '');
        }
        return wifiName;
      } catch (e) {
        return 'Unknown Wi-Fi';
      }
    }
    return 'Permission Denied (Cannot read SSID)';
  }
}
