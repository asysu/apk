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

  static final _probeUris = [
    Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
    Uri.parse('https://www.google.com/generate_204'),
    Uri.parse('https://cp.cloudflare.com/generate_204'),
  ];

  final Connectivity _connectivity;
  final http.Client _client;
  final ValueNotifier<bool?> isOnline = ValueNotifier(null);
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
      if (connections.isEmpty ||
          connections.every((connection) => connection == ConnectivityResult.none)) {
        _setOnline(false);
        return;
      }

      final probeResults = await Future.wait(
        _probeUris.map(_probeInternet),
      );
      _setOnline(probeResults.any((isReachable) => isReachable));
    } on Object catch (error) {
      if (isOnline.value == true) {
        debugPrint('Internet connectivity check failed: $error');
      }
      _setOnline(false);
    } finally {
      _checking = false;
    }
  }

  Future<bool> _probeInternet(Uri uri) async {
    try {
      final response = await _client
          .get(uri, headers: const {'cache-control': 'no-cache'})
          .timeout(const Duration(seconds: 3));
      return response.statusCode >= 200 && response.statusCode < 400;
    } on Object catch (error) {
      if (isOnline.value == true) {
        debugPrint('Internet probe failed for $uri: $error');
      }
      return false;
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
