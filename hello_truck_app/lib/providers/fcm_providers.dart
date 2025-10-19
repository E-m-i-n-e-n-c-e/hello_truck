import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/enums/fcm_enums.dart';
import '../services/fcm_service.dart';

final fcmServiceProvider = Provider<FCMService>((ref) {
  return FCMService();
});

final fcmEventStreamProvider = StreamProvider<FcmEventType>((ref) async* {
  final service = ref.watch(fcmServiceProvider);
  yield* service.eventStream;
});

final fcmEventsHandlerProvider = Provider<void>((ref) {
  ref.listen<AsyncValue<FcmEventType>>(fcmEventStreamProvider, (previous, next) {
    next.whenData((event) {
      // TODO: Handle FCM events
    });
  });
});