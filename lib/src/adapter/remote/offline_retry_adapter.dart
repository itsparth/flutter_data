import 'package:flutter_data/flutter_data.dart';

mixin OfflineRetryAdapter<T extends DataSupport<T>> on RemoteAdapter<T> {
  //  = RetryWhenStream<List<T>>(
  //   () {
  //     // return stream
  //   },
  //   (e, _) {
  //     if (e is SocketException) {
  //       // exponential backoff if network unreachable
  //       _i = _i * 2;
  //       if (_i <= 64) {
  //         return Rx.timer(null, Duration(seconds: _i));
  //       }
  //       // else give up and end this stream
  //       return Stream.empty();
  //     }
  //     throw e;
  //   }
  // ).asBroadcastStream();
}