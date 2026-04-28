import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/core/contact_email.dart';
import 'package:tds_voice_agent/model/agni_content.dart';
import 'package:tds_voice_agent/viewmodel/voice_viewmodel.dart';
import 'package:tds_voice_agent/widgets/background_painters.dart';
import 'package:tds_voice_agent/widgets/demo_video/demo_video_player.dart';
import 'package:tds_voice_agent/widgets/chatbot%20card/phone_mockup_widget.dart';

class HeroSection extends StatefulWidget {
  final AgniContent content;
  final bool isDark;

  const HeroSection({super.key, required this.content, required this.isDark});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with TickerProviderStateMixin {
  late AnimationController _globeController;
  late AnimationController _floatController;

  bool get isDark => widget.isDark;
  List<String> get _langs => widget.content.heroLangs;

  Color get textColor => isDark ? AgniColors.darkText : AgniColors.lightText;
  Color get text2Color => isDark ? AgniColors.darkText2 : AgniColors.lightText2;
  Color get text3Color => isDark ? AgniColors.darkText3 : AgniColors.lightText3;
  Gradient get gradText =>
      isDark ? AgniColors.gradText : AgniColors.gradTextLight;

  @override
  void initState() {
    super.initState();
    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _globeController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _openContactForm() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (_) => _ContactFormDialog(isDark: isDark),
    );
  }

  void _openDemoVideo() {
    context.read<VoiceViewModel>().stopAgentForDemoVideo();
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.8),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: const DemoVideoPlayer(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background globe (ignore pointers so scroll/gestures pass through)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _globeController,
              builder: (_, __) => IgnorePointer(
                child: CustomPaint(
                  painter: GlobeBgPainter(
                    isDark: isDark,
                    t: _globeController.value,
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        buildBadge(),
                        const SizedBox(height: 32),
                        _buildLangTicker(),
                        const SizedBox(height: 30),
                        _buildHeroTitle(isMobile: isMobile),
                        const SizedBox(height: 22),
                        _buildDescription(),
                        const SizedBox(height: 24),
                        _buildButtons(isMobile: isMobile),
                        const SizedBox(height: 32),
                        VoicePhoneWidget(
                          isDark: isDark,
                          heroLangs: _langs,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Text(
      widget.content.heroDescription,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        color: text3Color,
        height: 1.75,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildButtons({bool isMobile = false}) {
    void openExpert() => _openContactForm();
    void openDemo() => _openDemoVideo();

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _gradientButton('Talk to an expert', onTap: openExpert),
          const SizedBox(height: 10),
          _ghostButton('See how it works', onTap: openDemo),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _gradientButton('Talk to an expert', onTap: openExpert),
        const SizedBox(width: 10),
        _ghostButton('See how it works', onTap: openDemo),
      ],
    );
  }

  // Widget _buildHeroBadge() {
  //   return buildBadge();
  // }

  Widget buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AgniColors.oceanBright.withOpacity(0.08)
            : AgniColors.white.withOpacity(0.70),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? AgniColors.oceanBright.withOpacity(0.25)
              : AgniColors.oceanMid.withOpacity(0.16),
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AgniColors.oceanBright.withOpacity(0.10),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPulseDot(),
          const SizedBox(width: 8),
          Text(
            widget.content.heroBadge,
            style: TextStyle(
              fontSize: 12.8,
              fontWeight: FontWeight.w500,
              color: isDark ? AgniColors.oceanBright : AgniColors.oceanMid,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseDot() {
    return AnimatedBuilder(
      animation: _globeController,
      builder: (_, __) {
        final t = _globeController.value;
        final scale = 1.0 + (t - 0.5).abs() * 0.8;
        final opacity = 1.0 - (t - 0.5).abs() * 1.2;
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity.clamp(0.2, 1.0),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark
                    ? AgniColors.forestBright
                    : AgniColors.forestLight,
                shape: BoxShape.circle,
                boxShadow: isDark
                    ? [
                        BoxShadow(
                          color: AgniColors.forestBright.withOpacity(0.60),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangTicker() {
    final tags = widget.content.tickerTags;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: tags.asMap().entries.map((e) {
        return AnimatedBuilder(
          animation: _floatController,
          builder: (_, __) {
            final delay = e.key * 0.4;
            final t = ((_floatController.value + delay) % 1.0);
            final offset = math.sin(t * math.pi * 2) * 7;
            return Transform.translate(
              offset: Offset(0, offset),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0E2D4A).withOpacity(0.60)
                      : AgniColors.white.withOpacity(0.68),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: isDark
                        ? AgniColors.oceanBright.withOpacity(0.12)
                        : AgniColors.oceanMid.withOpacity(0.14),
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 13.6,
                    color: text2Color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildHeroTitle({required bool isMobile}) {
    final size = isMobile ? 48.0 : 72.0;
    final c = widget.content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          c.heroTitleLine1,
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: size,
            fontWeight: FontWeight.w900,
            height: 1.06,
            letterSpacing: -2.16,
            color: textColor,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                c.heroTitlePrefix,
                style: GoogleFonts.playfairDisplay(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  height: 1.06,
                  letterSpacing: -2.16,
                  color: textColor,
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => gradText.createShader(bounds),
                child: Text(
                  c.heroTitleAccent,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: size,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    height: 1.06,
                    letterSpacing: -2.16,
                    color: AgniColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gradientButton(String label, {bool small = false, VoidCallback? onTap}) {
    final child = Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(
        horizontal: small ? 26 : 36,
        vertical: small ? 10 : 16,
      ),
      decoration: BoxDecoration(
        gradient: AgniColors.grad,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: AgniColors.oceanBright.withOpacity(isDark ? 0.35 : 0.32),
            blurRadius: isDark ? 32 : 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
                      color: AgniColors.white,
          fontSize: small ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: AgniColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: child,
      ),
    );
  }

  Widget _ghostButton(String label, {VoidCallback? onTap}) {
    final child = Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E2D4A).withOpacity(0.50)
            : AgniColors.white.withOpacity(0.65),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isDark
              ? AgniColors.oceanBright.withOpacity(0.25)
              : AgniColors.oceanMid.withOpacity(0.20),
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text2Color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );

    if (onTap == null) return child;

    return Material(
      color: AgniColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: child,
      ),
    );
  }
}

class _ContactFormDialog extends StatefulWidget {
  final bool isDark;

  const _ContactFormDialog({required this.isDark});

  @override
  State<_ContactFormDialog> createState() => _ContactFormDialogState();
}

class _ContactFormDialogState extends State<_ContactFormDialog> {
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
    final didSend = await composeContactEmail(
      recipientEmail: emailController.text.trim(),
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      description: descController.text.trim(),
    );

    if (!mounted) return;
    if (didSend) {
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
