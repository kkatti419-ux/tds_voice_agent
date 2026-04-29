import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/contact_email.dart';

/// Same modal as hero **Talk to an expert** — used from navbar **Contact sales**.
void showContactFormDialog(
  BuildContext context, {
  required bool isDark,
  bool showSalesOfficeAddress = false,
}) {
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.6),
    builder: (_) => ContactFormDialog(
      isDark: isDark,
      showSalesOfficeAddress: showSalesOfficeAddress,
    ),
  );
}

class ContactFormDialog extends StatefulWidget {
  final bool isDark;
  final bool showSalesOfficeAddress;

  const ContactFormDialog({
    super.key,
    required this.isDark,
    this.showSalesOfficeAddress = false,
  });

  @override
  State<ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<ContactFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final descController = TextEditingController();
  bool submitted = false;

  bool get _dialogIsLight => widget.isDark;
  Color get _dialogBg => _dialogIsLight
      ? const Color(0xFFF0F7FF)
      : const Color(0xFF08162A).withOpacity(0.95);
  Color get _titleColor =>
      _dialogIsLight ? const Color(0xFF071828) : Colors.white;
  Color get _subtitleColor =>
      _dialogIsLight ? const Color(0xFF3A6A8A) : Colors.white60;
  Color get _inputTextColor =>
      _dialogIsLight ? const Color(0xFF071828) : Colors.white;
  Color get _hintColor =>
      _dialogIsLight ? const Color(0xFF7A9AB0) : Colors.white38;
  Color get _fieldFill =>
      _dialogIsLight ? const Color(0xFFE4F0F8) : Colors.white.withOpacity(0.05);
  Color get _enabledBorderColor =>
      _dialogIsLight ? const Color(0xFFB4D7EB) : Colors.white.withOpacity(0.10);
  Color get _dialogBorderColor => _dialogIsLight
      ? const Color(0xFF4EB3D3).withOpacity(0.20)
      : const Color(0xFF4EB3D3).withOpacity(0.25);
  Color get _dialogShadowColor => const Color(0xFF4EB3D3).withOpacity(0.25);

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    descController.dispose();
    super.dispose();
  }

  Future<void> _submitContactForm() async {
    if (!_formKey.currentState!.validate()) return;
    final result = await composeContactEmail(
      recipientEmail: emailController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      description: descController.text.trim(),
    );

    final bodyPreview = result.responseBody == null
        ? ''
        : result.responseBody!.length > 512
            ? '${result.responseBody!.substring(0, 512)}…'
            : result.responseBody!;
    developer.log(
      'composeContactEmail: success=${result.success} '
      'statusCode=${result.statusCode} '
      'error=${result.errorMessage} '
      'body=$bodyPreview',
      name: 'ContactFormDialog',
    );

    if (!mounted) return;
    if (result.success) {
      setState(() => submitted = true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to send email right now. Please try again.'),
      ),
    );
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.length < 2) return 'Enter full name (first & last)';
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value.trim())) {
      return 'Only letters allowed';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value.trim())) {
      return 'Enter valid 10-digit number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
      return 'Enter valid email';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _dialogBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _dialogBorderColor),
          boxShadow: [
            BoxShadow(
              color: _dialogShadowColor,
              blurRadius: 40,
              spreadRadius: 2,
            ),
          ],
        ),
        child: submitted ? _successView() : _formView(),
      ),
    );
  }

  Widget _successView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF52B788), size: 60),
        const SizedBox(height: 16),
        Text(
          "You're all set!",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Someone will get in touch with you shortly.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _subtitleColor, height: 1.5),
        ),
        const SizedBox(height: 24),
        _gradientButton('Close', () async {
          Navigator.of(context).pop();
        }),
      ],
    );
  }

  Widget _formView() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Talk to an Expert',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "We'll reach out within 24 hours",
            style: TextStyle(color: _subtitleColor),
          ),
          const SizedBox(height: 24),
          _inputField('Full Name', nameController, validator: _validateName),
          const SizedBox(height: 14),
          _inputField(
            'Phone Number',
            phoneController,
            keyboard: TextInputType.phone,
            validator: _validatePhone,
          ),
          const SizedBox(height: 14),
          _inputField(
            'Email Address',
            emailController,
            keyboard: TextInputType.emailAddress,
            validator: _validateEmail,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descController,
            maxLines: 3,
            style: TextStyle(color: _inputTextColor),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              return null;
            },
            decoration: _decoration('Description'),
          ),
          if (widget.showSalesOfficeAddress) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Company contact',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _subtitleColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,

              child: Text(
                'sales@technodysis.com',
                style: TextStyle(
                  color: _subtitleColor,
                  height: 1.45,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Office address',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _subtitleColor,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Subramanya Arcade\n'
              'Bannerghatta Rd, OLd Gurappanapalya, BTM 1st Stage, Bengaluru, Karnataka 560029, India',
              style: TextStyle(
                color: _subtitleColor,
                height: 1.45,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _gradientButton('Submit', _submitContactForm),
        ],
      ),
    );
  }

  Widget _inputField(
    String label,
    TextEditingController controller, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      style: TextStyle(color: _inputTextColor),
      validator: validator,
      decoration: _decoration(label),
    );
  }

  InputDecoration _decoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: _hintColor),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _enabledBorderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _enabledBorderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF4EB3D3), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  Widget _gradientButton(String text, Future<void> Function() onTap) {
    return GestureDetector(
      onTap: () => unawaited(onTap()),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4EB3D3), Color(0xFF52B788)],
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4EB3D3).withOpacity(0.4),
              blurRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
