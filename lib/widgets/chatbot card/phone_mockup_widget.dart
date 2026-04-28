import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';
import 'package:tds_voice_agent/viewmodel/voice_viewmodel.dart';

class VoicePhoneWidget extends StatefulWidget {
  final bool isDark;
  final List<String> heroLangs;

  const VoicePhoneWidget({
    super.key,
    required this.isDark,
    this.heroLangs = const [],
  });

  @override
  State<VoicePhoneWidget> createState() => _VoicePhoneWidgetState();
}

class _VoicePhoneWidgetState extends State<VoicePhoneWidget>
    with TickerProviderStateMixin {
  late AnimationController _orbController;
  late AnimationController _waveController;

  VoiceViewModel? _vm;
  Timer? _langTimer;
  int _langIndex = 0;
  double _langOpacity = 1.0;
  double _langOffset = 0.0;

  bool get isDark => widget.isDark;
  List<String> get _langs => widget.heroLangs;

  Color get textColor => isDark ? AgniColors.darkText : AgniColors.lightText;
  Color get text3Color => isDark ? AgniColors.darkText3 : AgniColors.lightText3;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    if (_langs.isNotEmpty) {
      _langTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _cycleLang();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_vm == null) {
      _vm = context.read<VoiceViewModel>();
      _vm!.addListener(_onVmChanged);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncWaveAnimation();
      });
    }
  }

  void _onVmChanged() {
    if (!mounted) return;
    _syncWaveAnimation();
    setState(() {});
  }

  void _syncWaveAnimation() {
    final vm = _vm;
    if (vm == null) return;
    final active = vm.isListening || vm.isAgentSpeaking;
    if (active) {
      if (!_waveController.isAnimating) {
        _waveController.repeat(reverse: true);
      }
      return;
    }
    if (_waveController.isAnimating) {
      _waveController.stop();
    }
    if (_waveController.value != 0.0) {
      _waveController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _cycleLang() async {
    if (!mounted || _langs.isEmpty) return;
    setState(() {
      _langOpacity = 0.0;
      _langOffset = 8.0;
    });
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _langIndex = (_langIndex + 1) % _langs.length;
      _langOpacity = 1.0;
      _langOffset = 0.0;
    });
  }

  @override
  void dispose() {
    _langTimer?.cancel();
    _vm?.removeListener(_onVmChanged);
    _orbController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Widget _offlineStrip() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Text(
        'No internet connection.',
        textAlign: TextAlign.center,
        style: AppTypography.bodyMedium(
          color: isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100),
        ).copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _micBlockedStrip(VoiceViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            vm.micBlockedMessage!,
            textAlign: TextAlign.center,
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium(
              color: isDark ? AgniColors.white70 : AgniColors.black54,
            ).copyWith(fontSize: 11, height: 1.3),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: vm.clearMicBlockedMessage,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AgniColors.white60 : AgniColors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _presenceCheckInStrip(VoiceViewModel vm) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        children: [
          Text(
            'Check-in sent — waiting for reply (voice will play here).',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(
              color: isDark ? AgniColors.white70 : AgniColors.black54,
            ).copyWith(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: vm.dismissPresenceCheckIn,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AgniColors.white60 : AgniColors.black45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _talkingAvatar() {
    return AnimatedBuilder(
      animation: _orbController,
      builder: (_, __) {
        final pulse = 0.08 + (_orbController.value * 0.12);
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 86 + pulse * 80,
              height: 86 + pulse * 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AgniColors.oceanBright.withOpacity(0.10),
              ),
            ),
            Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AgniColors.grad,
                boxShadow: [
                  BoxShadow(
                    color: AgniColors.oceanBright.withOpacity(
                      isDark ? 0.30 : 0.24,
                    ),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF0E2D4A).withOpacity(0.65)
                    : AgniColors.white.withOpacity(0.82),
                border: Border.all(
                  color: isDark
                      ? AgniColors.oceanBright.withOpacity(0.30)
                      : AgniColors.oceanMid.withOpacity(0.22),
                  width: 1.4,
                ),
              ),
              child: Icon(
                Icons.person,
                color: isDark ? AgniColors.oceanBright : AgniColors.oceanMid,
                size: 28,
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isWaveActive(VoiceViewModel vm) =>
      vm.isListening || vm.isAgentSpeaking;

  Widget _waveform(VoiceViewModel vm) {
    final heights = [
      20.0, 36.0, 48.0, 28.0, 40.0, 24.0, 44.0, 32.0, 20.0,
    ];
    final delays = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        if (!_isWaveActive(vm)) {
          return SizedBox(
            height: 48,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(13, (i) {
                return Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AgniColors.grad,
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: AgniColors.oceanBright.withValues(
                                alpha: 0.28,
                              ),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          );
        }
        return SizedBox(
          height: 48,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(heights.length, (i) {
              final phase = (_waveController.value + delays[i]) % 1.0;
              final scale = 0.3 + math.sin(phase * math.pi) * 0.7;
              return Container(
                width: 4,
                height: heights[i] * scale,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  gradient: AgniColors.grad,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: AgniColors.oceanBright.withOpacity(0.40),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }

  Widget _pricingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AgniColors.oceanBright.withOpacity(0.2)
              : AgniColors.oceanMid.withOpacity(0.18),
        ),
        color: isDark
            ? const Color(0xFF0E2D4A).withOpacity(0.45)
            : AgniColors.white.withOpacity(0.75),
      ),
      child: Column(
        children: [
          Text(
            'Pricing',
            style: AppTypography.bodyMedium(
              color: isDark ? AgniColors.white70 : AgniColors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹2 / min',
            style: AppTypography.displaySmall(
              color: isDark ? AgniColors.white : AgniColors.black,
            ).copyWith(fontSize: 22),
          ),
          Text(
            'AI Voice + Automation',
            style: AppTypography.bodyMedium(
              color: isDark ? AgniColors.white60 : AgniColors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueButtons(VoiceViewModel vm) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _pillButton(
          label: 'No',
          filled: false,
          onTap: () => vm.submitContinueIntent(false),
        ),
        const SizedBox(width: 12),
        _pillButton(
          label: 'Yes',
          filled: true,
          onTap: () => vm.submitContinueIntent(true),
        ),
      ],
    );
  }

  Widget _pillButton({
    required String label,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: filled
          ? (isDark ? AgniColors.white : AgniColors.black)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: filled
                  ? Colors.transparent
                  : (isDark ? AgniColors.white12 : AgniColors.black26),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: filled
                  ? (isDark ? AgniColors.black : AgniColors.white)
                  : (isDark ? AgniColors.white70 : AgniColors.black54),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusLabel(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        softWrap: true,
        style: AppTypography.bodyMedium(
          color: isDark ? AgniColors.white60 : AgniColors.black54,
        ).copyWith(fontSize: 13, height: 1.32),
      ),
    );
  }

  Widget _micButton(VoiceViewModel vm) {
    final muted = vm.micMutedByUser || !vm.isListening;
    return GestureDetector(
      onTap: vm.toggleListening,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          gradient: AgniColors.grad,
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: AgniColors.oceanBright.withOpacity(
                isDark ? 0.35 : 0.28,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          muted ? 'Tap to speak' : 'Mute mic',
          style: const TextStyle(
            color: AgniColors.white,
            fontSize: 13.6,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceViewModel>(
      builder: (_, vm, __) {
        return Center(
          child: Container(
            width: 340,
            height: 500,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF08162A).withOpacity(0.80)
                  : AgniColors.white.withOpacity(0.72),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: isDark
                    ? AgniColors.oceanBright.withOpacity(0.18)
                    : AgniColors.white.withOpacity(0.90),
                width: isDark ? 1 : 1.5,
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: AgniColors.oceanBright.withOpacity(0.20),
                        blurRadius: 80,
                      ),
                      BoxShadow(
                        color: const Color(0xFF000000).withOpacity(0.40),
                        blurRadius: 24,
                        offset: const Offset(0, 24),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0xFF0A2342).withOpacity(0.22),
                        blurRadius: 80,
                        offset: const Offset(0, 20),
                      ),
                    ],
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    gradient: LinearGradient(
                      begin: const Alignment(-0.7, -0.9),
                      end: const Alignment(1, 1),
                      colors: isDark
                          ? [
                              AgniColors.oceanBright.withOpacity(0.06),
                              AgniColors.forestLight.withOpacity(0.05),
                            ]
                          : [
                              const Color(0xFFB4D7EB).withOpacity(0.22),
                              const Color(0xFFB4E1C8).withOpacity(0.18),
                            ],
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      width: 80,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AgniColors.oceanBright.withOpacity(0.15)
                            : AgniColors.oceanMid.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(14, 40, 14, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (vm.isOffline) _offlineStrip(),
                      if (vm.micBlockedMessage != null) _micBlockedStrip(vm),
                      if (vm.presenceCheckSent) _presenceCheckInStrip(vm),
                      _statusLabel(vm.statusText),
                      const SizedBox(height: 10),
                      Center(child: _talkingAvatar()),
                      const SizedBox(height: 14),
                      Center(child: _waveform(vm)),
                      if (_langs.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 400),
                          opacity: _langOpacity,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            transform: Matrix4.translationValues(
                              0,
                              _langOffset,
                              0,
                            ),
                            child: Text(
                              _langs[_langIndex],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 27.2,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        'Agentic copilots · 24/7 uptime',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.dmMono(
                          fontSize: 12.48,
                          color: text3Color,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _pricingCard(),
                      if (vm.showContinueButtons) ...[
                        const SizedBox(height: 12),
                        _continueButtons(vm),
                      ],
                      const SizedBox(height: 16),
                      Center(child: _micButton(vm)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
