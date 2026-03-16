import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show ValueNotifier, VoidCallback, kIsWeb;

enum ConnectionStatus {
  online,
  offline,
  unknown,
}

bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  Timer? _desktopPollTimer;

  final ValueNotifier<ConnectionStatus> status = ValueNotifier(ConnectionStatus.unknown);
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  final List<VoidCallback> _onConnectedCallbacks = [];
  final List<VoidCallback> _onDisconnectedCallbacks = [];

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (_isDesktop) {
      // Don't block startup — run first check in background
      _httpReachabilityCheck();
      _desktopPollTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) => _httpReachabilityCheck(),
      );
    } else {
      await _checkConnectivity();
      _subscription = _connectivity.onConnectivityChanged.listen(_handleConnectivityChange);
    }
  }

  Future<void> _httpReachabilityCheck() async {
    final wasOnline = isOnline.value;
    try {
      final result = await InternetAddress.lookup('example.com')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        status.value = ConnectionStatus.online;
        isOnline.value = true;
      } else {
        status.value = ConnectionStatus.offline;
        isOnline.value = false;
      }
    } catch (_) {
      status.value = ConnectionStatus.offline;
      isOnline.value = false;
    }

    if (!wasOnline && isOnline.value) {
      for (final callback in _onConnectedCallbacks) {
        callback();
      }
    } else if (wasOnline && !isOnline.value) {
      for (final callback in _onDisconnectedCallbacks) {
        callback();
      }
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _handleConnectivityChange(ConnectivityResult result) {
    final wasOnline = isOnline.value;
    _updateStatus(result);

    if (!wasOnline && isOnline.value) {
      for (final callback in _onConnectedCallbacks) {
        callback();
      }
    } else if (wasOnline && !isOnline.value) {
      for (final callback in _onDisconnectedCallbacks) {
        callback();
      }
    }
  }

  void _updateStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      status.value = ConnectionStatus.offline;
      isOnline.value = false;
    } else {
      status.value = ConnectionStatus.online;
      isOnline.value = true;
    }
  }

  Future<bool> checkIsOnline() async {
    if (_isDesktop) {
      try {
        final result = await InternetAddress.lookup('example.com')
            .timeout(const Duration(seconds: 2));
        return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        return false;
      }
    }
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<String> getConnectionType() async {
    if (_isDesktop) {
      return isOnline.value ? 'Desktop' : 'None';
    }
    final result = await _connectivity.checkConnectivity();
    switch (result) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
        return 'None';
      default:
        return 'Unknown';
    }
  }

  void onConnected(VoidCallback callback) {
    _onConnectedCallbacks.add(callback);
  }

  void onDisconnected(VoidCallback callback) {
    _onDisconnectedCallbacks.add(callback);
  }

  void removeOnConnected(VoidCallback callback) {
    _onConnectedCallbacks.remove(callback);
  }

  void removeOnDisconnected(VoidCallback callback) {
    _onDisconnectedCallbacks.remove(callback);
  }

  Stream<ConnectionStatus> get statusStream {
    return _connectivity.onConnectivityChanged.map((result) {
      if (result == ConnectivityResult.none) {
        return ConnectionStatus.offline;
      }
      return ConnectionStatus.online;
    });
  }

  void dispose() {
    _subscription?.cancel();
    _desktopPollTimer?.cancel();
    _onConnectedCallbacks.clear();
    _onDisconnectedCallbacks.clear();
  }
}
