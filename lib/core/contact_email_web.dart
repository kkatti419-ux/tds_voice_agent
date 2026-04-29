import 'dart:convert';
import 'dart:html' as html;

import 'compose_contact_email_result.dart';

Future<ComposeContactEmailResult> composeContactEmail({
  required String recipientEmail,
  required String name,
  required String phone,
  required String description,
}) async {
  try {
    if (recipientEmail.isEmpty || !recipientEmail.contains('@')) {
      html.window.console.error('Invalid email: $recipientEmail');
      return const ComposeContactEmailResult(
        success: false,
        errorMessage: 'Invalid recipient email',
      );
    }

    const endpoint = 'https://demo.nitya.ai/send-mail';

    final request = await html.HttpRequest.request(
      endpoint,
      method: 'POST',
      sendData: jsonEncode({
        'name': name,
        'phone': phone,
        'description': description,
        'user_email': recipientEmail,
      }),
      requestHeaders: {
        'Content-Type': 'application/json',
      },
    );

    final status = request.status ?? 0;
    final body = request.responseText ?? '';
    final ok = status >= 200 && status < 300;
    return ComposeContactEmailResult(
      success: ok,
      statusCode: status,
      responseBody: body.isEmpty ? null : body,
    );
  } catch (error) {
    html.window.console.error('mail submit failed: $error');
    return ComposeContactEmailResult(
      success: false,
      errorMessage: error.toString(),
    );
  }
}
