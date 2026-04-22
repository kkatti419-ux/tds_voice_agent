// Web-only: VM analyzer does not resolve dart:js_util; Flutter/web builds use it.
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;
import 'dart:typed_data';

Future<Object?> decodeAudioDataPromise(dynamic ctx, ByteBuffer buffer) {
  return js_util.promiseToFuture<Object?>(ctx.decodeAudioData(buffer));
}

void setBufferSourceOnEnded(dynamic src, void Function() onDone) {
  js_util.setProperty(
    src,
    'onended',
    js_util.allowInterop((_) {
      onDone();
    }),
  );
}

Future<Object?> resumeAudioContextPromise(dynamic ctx) {
  return js_util.promiseToFuture<Object?>(ctx.resume());
}
