/// Result of attempting to send the contact form via [composeContactEmail].
class ComposeContactEmailResult {
  const ComposeContactEmailResult({
    required this.success,
    this.statusCode,
    this.responseBody,
    this.errorMessage,
  });

  final bool success;
  final int? statusCode;
  final String? responseBody;
  final String? errorMessage;
}
