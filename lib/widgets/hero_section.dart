import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/domain/entities/agni_content.dart';
import 'package:tds_voice_agent/widgets/background_painters.dart';
import 'package:tds_voice_agent/widgets/3/phone_mockup_widget.dart';

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
  late AnimationController _waveController;
  late AnimationController _floatController;

  int _langIndex = 0;
  double _langOpacity = 1.0;
  double _langOffset = 0.0;
  Timer? _langTimer;

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
      duration: const Duration(seconds: 10),
    )..repeat();

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    if (_langs.isNotEmpty) {
      _langTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        _cycleLang();
      });
    }
  }

  void _cycleLang() async {
    if (!mounted) return;
    setState(() {
      _langOpacity = 0.0;
      _langOffset = 8.0;
    });
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    setState(() {
      _langIndex = (_langIndex + 1) % _langs.length;
      _langOpacity = 1.0;
      _langOffset = 0.0;
    });
  }

  @override
  void dispose() {
    _globeController.dispose();
    _waveController.dispose();
    _floatController.dispose();
    _langTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background globe animation
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _globeController,
              builder: (_, __) => CustomPaint(
                painter: GlobeBgPainter(
                  isDark: isDark,
                  t: _globeController.value,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;

                if (isMobile) {
                  return Column(
                    children: [
                      buildBadge(),
                      const SizedBox(height: 16),
                      _buildLangTicker(),
                      const SizedBox(height: 24),
                      _buildHeroTitle(isMobile: true),
                      const SizedBox(height: 24),
                      _buildDescription(),
                      const SizedBox(height: 32),
                      _buildButtons(isMobile: true),
                      const SizedBox(height: 60),
                      // _buildPhoneMockup(),
                      VoicePhoneWidget(
                        isDark: true,
                        // languages: ["English", "Hindi", "Tamil"],
                        // floatingCards: [
                        //   FloatingCardData(
                        //     "100K+",
                        //     "Daily calls",
                        //     0.0,
                        //   ), // stat, label, delayFactor
                        //   FloatingCardData("\$0.03", "Cost/min", 0.0),
                        // ],
                      ),
                      // PhoneMockupWidget(
                      //   isDark: true,
                      //   languages: ["English", "Hindi", "Tamil"],
                      //   floatingCards: [
                      //     FloatingCardData(
                      //       "100K+",
                      //       "Daily calls",
                      //       0.0,
                      //     ), // stat, label, delayFactor
                      //     FloatingCardData("\$0.03", "Cost/min", 0.0),
                      //   ],
                      // ),
                    ],
                  );
                } else {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildBadge(),
                            const SizedBox(height: 16),
                            _buildLangTicker(alignLeft: true),
                            const SizedBox(height: 24),
                            _buildHeroTitle(isMobile: false),
                            const SizedBox(height: 24),
                            _buildDescription(alignLeft: true),
                            const SizedBox(height: 32),
                            _buildButtons(isMobile: false),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48),
                      // Mockup container
                      SizedBox(
                        width: 320,
                        child: VoicePhoneWidget(
                          isDark: true,
                          // languages: ["English", "Hindi", "Tamil"],
                          // floatingCards: [
                          //   FloatingCardData(
                          //     "100K+",
                          //     "Daily calls",
                          //     0.0,
                          //   ), // stat, label, delayFactor
                          //   FloatingCardData("\$0.03", "Cost/min", 0.0),
                          // ],
                        ),
                        // PhoneMockupWidget(
                        //   isDark: true,
                        //   languages: ["English", "Hindi", "Tamil"],
                        //   floatingCards: [
                        //     FloatingCardData(
                        //       "100K+",
                        //       "Daily calls",
                        //       0.0,
                        //     ), // stat, label, delayFactor
                        //     FloatingCardData("\$0.03", "Cost/min", 0.0),
                        //   ],
                        // ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription({bool alignLeft = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: RichText(
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        text: TextSpan(
          style: TextStyle(fontSize: 16, height: 1.7, color: text3Color),
          children: [
            const TextSpan(text: 'We build '),

            /// 🔥 Highlight
            WidgetSpan(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
                ).createShader(bounds),
                child: const Text(
                  'agentic AI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const TextSpan(text: ' and automation that transforms '),

            /// 🔥 Industries highlight
            WidgetSpan(
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0xFF4EB3D3), Color(0xFF74C69D)],
                ).createShader(bounds),
                child: const Text(
                  'Healthcare, Banking, Insurance, Telecom, and Retail',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            const TextSpan(text: ' — with measurable ROI from day one.'),
          ],
        ),
      ),
    );
  }
  // Widget _buildDescription({bool alignLeft = false}) {
  //   return Text(
  //     'We build agentic AI and automation that transforms Healthcare, Banking, Insurance, Telecom, and Retail — with measurable ROI from day one.',
  //     textAlign: alignLeft ? TextAlign.left : TextAlign.center,
  //     style: TextStyle(fontSize: 16, color: text3Color, height: 1.6),
  //   );
  // }

  Widget _buildButtons({bool isMobile = false}) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _gradientButton('Talk to an expert'),
          const SizedBox(height: 12),
          _ghostButton('See how it works'),
        ],
      );
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _gradientButton('Talk to an expert'),
        const SizedBox(width: 12),
        _ghostButton('See how it works'),
      ],
    );
  }

  // Widget _buildHeroBadge() {
  //   return buildBadge();
  // }

  Widget buildBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),

        /// 🌫️ Glass effect
        color: isDark
            ? const Color(0xFF0E2D4A).withOpacity(0.35)
            : Colors.white.withOpacity(0.6),

        /// 🧊 Border
        border: Border.all(
          color: isDark
              ? AgniColors.oceanBright.withOpacity(0.25)
              : AgniColors.oceanMid.withOpacity(0.2),
        ),

        /// ✨ Glow
        boxShadow: [
          BoxShadow(
            color: isDark
                ? AgniColors.oceanBright.withOpacity(0.15)
                : AgniColors.oceanMid.withOpacity(0.1),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// 🔵 Animated Pulse Dot
          _buildPulseDot(),

          const SizedBox(width: 10),

          /// 🌈 Gradient Text
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: isDark
                  ? [AgniColors.oceanBright, AgniColors.forestBright]
                  : [AgniColors.oceanMid, AgniColors.forestMid],
            ).createShader(bounds),
            child: const Text(
              'Founded in 2020 · Bangalore HQ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white, // required for shader
                letterSpacing: 0.3,
              ),
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

  Widget _buildLangTicker({bool alignLeft = false}) {
    final tags = widget.content.tickerTags;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: alignLeft ? WrapAlignment.start : WrapAlignment.center,
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
                      : Colors.white.withOpacity(0.68),
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
    return Column(
      crossAxisAlignment: isMobile
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Text(
          'Agentic AI + Automation',
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          style: GoogleFonts.playfairDisplay(
            fontSize: isMobile ? 48 : 64,
            fontWeight: FontWeight.w900,
            height: 1.06,
            letterSpacing: -2.16,
            color: textColor,
          ),
        ),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          children: [
            Text(
              'for modern ',
              style: GoogleFonts.playfairDisplay(
                fontSize: isMobile ? 48 : 64,
                fontWeight: FontWeight.w900,
                height: 1.06,
                letterSpacing: -2.16,
                color: textColor,
              ),
            ),
            ShaderMask(
              shaderCallback: (bounds) => gradText.createShader(bounds),
              child: Text(
                'enterprises.',
                style: GoogleFonts.playfairDisplay(
                  fontSize: isMobile ? 48 : 64,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  height: 1.06,
                  letterSpacing: -2.16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final heights = [20.0, 36.0, 48.0, 28.0, 40.0, 24.0, 44.0, 32.0, 20.0];
    final delays = [0.0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8];
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) => SizedBox(
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
      ),
    );
  }

  Widget _buildTalkingAvatar() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (_, __) {
        final pulse = 0.08 + (_waveController.value * 0.12);
        return Stack(
          alignment: Alignment.center,
          children: [
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
                    : Colors.white.withOpacity(0.82),
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
            Container(
              width: 86 + pulse * 80,
              height: 86 + pulse * 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AgniColors.oceanBright.withOpacity(0.10),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFloatingCard(String stat, String label, double delayFactor) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (_, __) {
        final t =
            ((_floatController.value * (1 / 4.0)) + delayFactor / 4.0) % 1.0;
        final offset = math.sin(t * math.pi * 2) * 7;
        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF08162A).withOpacity(0.88)
                  : Colors.white.withOpacity(0.88),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? AgniColors.oceanBright.withOpacity(0.25)
                    : Colors.white.withOpacity(0.95),
              ),
              boxShadow: [
                BoxShadow(
                  color: AgniColors.oceanBright.withOpacity(
                    isDark ? 0.10 : 0.08,
                  ),
                  blurRadius: 48,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => gradText.createShader(bounds),
                  child: Text(
                    stat,
                    style: const TextStyle(
                      fontSize: 17.6,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.8,
                    color: text2Color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _gradientButton(String label, {bool small = false}) {
    return Container(
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
          color: Colors.white,
          fontSize: small ? 14 : 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _ghostButton(String label) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0E2D4A).withOpacity(0.50)
            : Colors.white.withOpacity(0.65),
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
  }
}
