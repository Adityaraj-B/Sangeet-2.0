import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Service managing device connectivity and internet reachability.
///
/// Features:
/// 1. Real-time detection of offline/online state via [Connectivity] and active DNS ping.
/// 2. Notifies when internet is disconnected (offline) and when restored (reconnected).
/// 3. Automatically checks connection on app resume and on periodic intervals.
class ConnectivityService with WidgetsBindingObserver {
  static final ConnectivityService instance = ConnectivityService._internal();

  ConnectivityService._internal() {
    _init();
  }

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _periodicTimer;

  /// Reactive notifier for current internet connectivity.
  /// `true` = online, `false` = offline.
  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);

  /// Reactive notifier indicating the app just transitioned from offline to online.
  /// Automatically resets to `false` after 4 seconds.
  final ValueNotifier<bool> justReconnectedNotifier = ValueNotifier<bool>(false);

  Timer? _reconnectedResetTimer;
  bool _wasOffline = false;
  bool _isChecking = false;

  bool get isOnline => isOnlineNotifier.value;
  bool get justReconnected => justReconnectedNotifier.value;

  void _init() {
    try {
      WidgetsBinding.instance.addObserver(this);
    } catch (_) {}

    // Listen to network interface changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateConnectivity(results);
    });

    // Periodic check every 12 seconds in case Wi-Fi/Cellular has no actual internet
    _periodicTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      checkConnection();
    });

    // Initial check
    checkConnection();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      checkConnection();
    }
  }

  /// Evaluates connection status based on network interface results.
  Future<void> _evaluateConnectivity(List<ConnectivityResult> results) async {
    final hasInterface = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);

    if (!hasInterface) {
      _setOffline();
      return;
    }

    // Network interface is available; verify actual reachability
    final reachable = await _pingInternet();
    if (reachable) {
      _setOnline();
    } else {
      _setOffline();
    }
  }

  /// Public callback for API repositories to notify that a network request failed (e.g. SocketException)
  void notifyNetworkError() {
    _setOffline();
  }

  /// Actively tests whether the internet is reachable with short timeouts.
  Future<bool> _pingInternet() async {
    try {
      // 1. DNS query on a real hostname (requires working internet DNS)
      final res = await InternetAddress.lookup('dns.google')
          .timeout(const Duration(milliseconds: 1800));
      if (res.isNotEmpty && res[0].rawAddress.isNotEmpty) {
        return true;
      }
    } catch (_) {}

    try {
      // 2. Direct TCP socket connect to Cloudflare DNS (port 53)
      final socket = await Socket.connect(
        '1.1.1.1',
        53,
        timeout: const Duration(milliseconds: 1800),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    try {
      // 3. Direct TCP socket connect to Google DNS (port 53)
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(milliseconds: 1800),
      );
      socket.destroy();
      return true;
    } catch (_) {}

    return false;
  }

  void _setOffline() {
    _wasOffline = true;
    _reconnectedResetTimer?.cancel();
    justReconnectedNotifier.value = false;
    if (isOnlineNotifier.value) {
      isOnlineNotifier.value = false;
    }
  }

  void _setOnline() {
    final previouslyOffline = _wasOffline || !isOnlineNotifier.value;
    isOnlineNotifier.value = true;

    if (previouslyOffline) {
      _wasOffline = false;
      justReconnectedNotifier.value = true;
      _reconnectedResetTimer?.cancel();
      _reconnectedResetTimer = Timer(const Duration(seconds: 4), () {
        justReconnectedNotifier.value = false;
      });
    }
  }

  /// Manually checks and refreshes connectivity status (e.g. on pull-to-refresh).
  Future<bool> checkConnection() async {
    if (_isChecking) return isOnlineNotifier.value;
    _isChecking = true;

    try {
      final results = await _connectivity.checkConnectivity();
      final hasInterface = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);

      if (!hasInterface) {
        _setOffline();
        _isChecking = false;
        return false;
      }

      final reachable = await _pingInternet();
      if (reachable) {
        _setOnline();
        _isChecking = false;
        return true;
      } else {
        _setOffline();
        _isChecking = false;
        return false;
      }
    } catch (e) {
      _isChecking = false;
      return isOnlineNotifier.value;
    }
  }

  void dispose() {
    try {
      WidgetsBinding.instance.removeObserver(this);
    } catch (_) {}
    _connectivitySub?.cancel();
    _periodicTimer?.cancel();
    _reconnectedResetTimer?.cancel();
  }
}
