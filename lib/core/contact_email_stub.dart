import 'compose_contact_email_result.dart';

Future<ComposeContactEmailResult> composeContactEmail({
  required String recipientEmail,
  required String name,
  required String phone,
  required String description,
}) async {
  return const ComposeContactEmailResult(
    success: false,
    errorMessage: 'composeContactEmail not available on this platform',
  );
}
