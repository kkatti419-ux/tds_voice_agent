// Web-only: VM analyzer does not resolve dart:js_util; Flutter/web builds use it.
// ignore: uri_does_not_exist
import 'dart:js_util' as js_util;
import 'dart:typed_data';

/// Calls `AudioContext.decodeAudioData` via JS — dynamic `ctx.decodeAudioData` fails on dart2js/DDC.
Future<Object?> decodeAudioDataPromise(dynamic ctx, ByteBuffer buffer) async {
  final Object? ret = js_util.callMethod<Object?>(
    ctx,
    'decodeAudioData',
    <Object>[buffer],
  );
  if (ret == null) return null;
  try {
    return await js_util.promiseToFuture<Object?>(ret);
  } catch (e) {
    final s = e.toString();
    if (s.contains('non-function') || s.contains('is not a function')) {
      return null;
    }
    rethrow;
  }
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

Future<Object?> resumeAudioContextPromise(dynamic ctx) async {
  final Object? ret = js_util.callMethod<Object?>(
    ctx,
    'resume',
    const <Object>[],
  );
  if (ret == null) return null;
  try {
    return await js_util.promiseToFuture<Object?>(ret);
  } catch (e) {
    final s = e.toString();
    if (s.contains('non-function') || s.contains('is not a function')) {
      return null;
    }
    rethrow;
  }
}

/// [window.AudioContext] via [js_util.globalThis] — avoids `window as dynamic`
/// lookups that fail under dart2js/DDC (`NoSuchMethodError: AudioContext`).
dynamic createAudioContextOrNull() {
  try {
    final g = js_util.globalThis;
    final ctor = js_util.getProperty(g, 'AudioContext') ??
        js_util.getProperty(g, 'webkitAudioContext');
    if (ctor == null) return null;
    return js_util.callConstructor(ctor, const <Object>[]);
  } catch (_) {
    return null;
  }
}

/// Raw JS `AudioContext.createBufferSource()` call.
dynamic audioContextCreateBufferSource(dynamic audioContext) {
  return js_util.callMethod<Object?>(
    audioContext,
    'createBufferSource',
    const <Object>[],
  );
}

void audioBufferSourceSetBuffer(dynamic src, Object? audioBuffer) {
  js_util.setProperty(src, 'buffer', audioBuffer);
}

void audioBufferSourceConnectToContextDestination(
  dynamic src,
  dynamic audioContext,
) {
  final destination = js_util.getProperty(audioContext, 'destination');
  js_util.callMethod<Object?>(src, 'connect', <Object?>[destination]);
}

void audioBufferSourceSetPlaybackRate(dynamic src, double rate) {
  final Object? param = js_util.getProperty(src, 'playbackRate');
  if (param != null) {
    js_util.setProperty(param, 'value', rate);
  }
}

void audioBufferSourceStart(dynamic src, double when) {
  js_util.callMethod<Object?>(src, 'start', <Object?>[when]);
}

void audioBufferSourceStop(dynamic src, double when) {
  try {
    js_util.callMethod<Object?>(src, 'stop', <Object?>[when]);
  } catch (_) {}
}

void audioBufferSourceDisconnect(dynamic src) {
  try {
    js_util.callMethod<Object?>(src, 'disconnect', const <Object>[]);
  } catch (_) {}
}

/// Calls `HTMLMediaElement.play()` through JS and awaits a real Promise only.
/// Dart's typed [AudioElement.play] can throw [JSNoSuchMethodError] when the
/// engine returns `undefined` or a non-standard thenable (common on first play).
Future<void> playMediaElement(Object audioElement) async {
  final Object? ret = js_util.callMethod<Object?>(
    audioElement,
    'play',
    const <Object>[],
  );
  if (ret == null) return;
  try {
    await js_util.promiseToFuture<void>(ret);
  } catch (e) {
    final s = e.toString();
    if (s.contains('non-function') || s.contains('is not a function')) {
      return;
    }
    rethrow;
  }
}
