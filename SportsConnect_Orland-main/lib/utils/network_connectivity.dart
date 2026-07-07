import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:orland_sports/enums/network_status.dart';

class NetworkConnectivity {
  //singleton instance
  static NetworkConnectivity get instance => NetworkConnectivity();

  StreamController<NetworkStatus> networkStatusStream =
      StreamController<NetworkStatus>();

  //method to check if the device is connected to network
  Future<NetworkStatus> getNetworkStatus() async {
    //initializing ConnectivityResult
    List<ConnectivityResult> _result = await Connectivity().checkConnectivity();

    //checking if the device is connected to cellular or wifi network
    NetworkStatus _networkStatus =
        _result.contains(ConnectivityResult.mobile) ||
                _result.contains(ConnectivityResult.wifi)
            ? NetworkStatus.online
            : NetworkStatus.offline;

    return _networkStatus;
  }
}
