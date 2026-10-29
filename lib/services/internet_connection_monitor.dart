import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class InternetConnectionMonitor {
  InternetConnectionMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  final ValueNotifier<bool?> isOnline = ValueNotifier(null);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  int _consecutiveOfflineChecks = 0;
  bool _checking = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_disposed) return;
    _subscription = _connectivity.onConnectivityChanged.listen(
      (_) => unawaited(check()),
      onError: (Object error) {
        debugPrint('Network state monitoring failed: $error');
        unawaited(check());
      },
    );
    _retryTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => unawaited(check()),
    );
    await check();
  }

  Future<void> check() async {
    if (_checking || _disposed) return;
    _checking = true;
    try {
      final connections = await _connectivity.checkConnectivity();
      if (_disposed) return;
      if (connections
          .any((connection) => connection != ConnectivityResult.none)) {
        _consecutiveOfflineChecks = 0;
        _setOnline(true);
        return;
      }

      _consecutiveOfflineChecks++;
      // Allow Android time to discover the network during the first launch.
      if (_consecutiveOfflineChecks >= 2 || isOnline.value == true) {
        _setOnline(false);
      }
    } on Object catch (error) {
      debugPrint('Network state check failed: $error');
    } finally {
      _checking = false;
    }
  }

  void _setOnline(bool value) {
    if (!_disposed && isOnline.value != value) isOnline.value = value;
  }

  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    unawaited(_subscription?.cancel());
    isOnline.dispose();
  }
}
