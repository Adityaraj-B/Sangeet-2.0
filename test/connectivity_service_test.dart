import 'package:flutter_test/flutter_test.dart';
import 'package:sangeet/services/connectivity_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ConnectivityService - Online & Offline State Detection', () {
    test('Default instance provides valid initial state', () {
      final service = ConnectivityService.instance;
      expect(service.isOnlineNotifier.value, isNotNull);
      expect(service.justReconnectedNotifier.value, isFalse);
    });

    test('isOnline getter matches isOnlineNotifier value', () {
      final service = ConnectivityService.instance;
      service.isOnlineNotifier.value = false;
      expect(service.isOnline, isFalse);

      service.isOnlineNotifier.value = true;
      expect(service.isOnline, isTrue);
    });

    test('justReconnected getter matches justReconnectedNotifier value', () {
      final service = ConnectivityService.instance;
      service.justReconnectedNotifier.value = true;
      expect(service.justReconnected, isTrue);

      service.justReconnectedNotifier.value = false;
      expect(service.justReconnected, isFalse);
    });

    test('notifyNetworkError sets isOnline to false', () {
      final service = ConnectivityService.instance;
      service.isOnlineNotifier.value = true;
      service.notifyNetworkError();
      expect(service.isOnline, isFalse);
    });

    test('checkConnection executes without unhandled errors', () async {
      final service = ConnectivityService.instance;
      final result = await service.checkConnection();
      expect(result, isA<bool>());
    });
  });
}
