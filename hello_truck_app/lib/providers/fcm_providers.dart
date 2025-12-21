import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hello_truck_app/models/enums/fcm_enums.dart';
import 'package:hello_truck_app/providers/booking_providers.dart';
import 'package:hello_truck_app/providers/customer_providers.dart';
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
      if(event == FcmEventType.bookingStatusChange) {
        ref.invalidate(activeBookingsProvider);
        ref.invalidate(bookingDetailsProvider);
        ref.invalidate(bookingHistoryProvider);
      }
      if(event == FcmEventType.paymentSuccess) {
        ref.invalidate(activeBookingsProvider);
        ref.invalidate(bookingDetailsProvider);
      }
      if(event == FcmEventType.refundProcessed) {
        ref.invalidate(pendingRefundsProvider);
        ref.invalidate(transactionLogsProvider);
        ref.invalidate(walletLogsProvider);
        ref.invalidate(customerProvider);
      }
      if(event == FcmEventType.walletChange) {
        ref.invalidate(walletLogsProvider);
        ref.invalidate(customerProvider);
      }
    });
  });
});