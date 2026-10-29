import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class InternetConnectionMonitor {
  InternetConnectionMonitor({
    Connectivity? connectivity,
    http.Client? client,
  })  : _connectivity = connectivity ?? Connectivity(),
        _client = client ?? http.Client();

  static final _probeUri =
      Uri.parse('https://connectivitycheck.gstatic.com/generate_204');

  final Connectivity _connectivity;
  final http.Client _client;
  final ValueNotifier<bool> isOnline = ValueNotifier(false);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;
  bool _checking = false;
  bool _disposed = false;

  Future<void> start() async {
    if (_disposed) return;
    _subscription = _connectivity.onConnectivityChanged.listen(
      (_) => unawaited(check()),
      onError: (Object error) {
        debugPrint('Network state monitoring failed: $error');
        _setOnline(false);
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
      if (connections.contains(ConnectivityResult.none)) {
        _setOnline(false);
        return;
      }

      final response = await _client
          .get(_probeUri, headers: const {'cache-control': 'no-cache'})
          .timeout(const Duration(seconds: 2));
      _setOnline(response.statusCode == 204);
    } on Object catch (error) {
      if (isOnline.value) {
        debugPrint('Internet connectivity check failed: $error');
      }
      _setOnline(false);
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
    _client.close();
    isOnline.dispose();
  }
}
