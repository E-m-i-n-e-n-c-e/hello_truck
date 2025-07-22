import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final _controller = StreamController<bool>.broadcast(); // true = online
  late final StreamSubscription _subscription;

  ConnectivityService() {
    _subscription = Connectivity().onConnectivityChanged.listen(_handleChange);
    _initializeStatus(); // check initial state
  }

  final _connectivity = Connectivity();

  Stream<bool> get connectivityStream => _controller.stream;

  void _handleChange(List<ConnectivityResult> results) {
    _controller.add(results.any((result) => result != ConnectivityResult.none));
  }

  void _initializeStatus() async {
    final results = await _connectivity.checkConnectivity();
    _controller.add(results.any((result) => result != ConnectivityResult.none));
  }

  void dispose() {
    _subscription.cancel();
    _controller.close();
  }
}