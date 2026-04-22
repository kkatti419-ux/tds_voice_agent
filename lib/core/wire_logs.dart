import 'package:flutter/foundation.dart';

/// HTML-style wire logging in Flutter Web DevTools.
///
/// - Always on in [kDebugMode].
/// - In profile/release, pass `--dart-define=AGNI_WIRE_LOGS=true` (or `1`).
const String _agniWireLogsEnv =
    String.fromEnvironment('AGNI_WIRE_LOGS', defaultValue: '');

/// Enable AgniApp-style message / audio chunk console output.
bool get agniWireLogsEnabled =>
    kDebugMode ||
    _agniWireLogsEnv == 'true' ||
    _agniWireLogsEnv == '1';
