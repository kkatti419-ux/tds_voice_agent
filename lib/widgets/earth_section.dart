import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/widgets/cta_section.dart';
import 'package:tds_voice_agent/widgets/earth_global_container.dart';

class EarthSection extends StatefulWidget {
  final List<LangItem> langPills;
  final bool isDark;

  const EarthSection({
    super.key,
    required this.langPills,
    required this.isDark,
  });

  @override
  State<EarthSection> createState() => _EarthSectionState();
}

class LangItem {
  final String label;
  final String type;

  LangItem(this.label, this.type);

  @override
  String toString() => label;
}

class _EarthSectionState extends State<EarthSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _globeController;

  @override
  void initState() {
    super.initState();
    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _globeController.dispose();
    super.dispose();
  }

  Color get textColor => widget.isDark ? Colors.white : Colors.black;
  Color get text3Color => widget.isDark ? Colors.white60 : Colors.black54;

  final LinearGradient gradText = const LinearGradient(
    colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)],
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      child: Column(
        children: [
          const Text(
            "Global delivery",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 18),

          /// 🔥 Title
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.2,
                color: textColor,
              ),
              children: [
                const TextSpan(text: "Built in Bangalore.\nDelivered across "),
                WidgetSpan(
                  child: ShaderMask(
                    shaderCallback: (b) => gradText.createShader(b),
                    child: Text(
                      'the world.',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          Text(
            "Technodysis builds from Bangalore and delivers globally.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: text3Color),
          ),

          const SizedBox(height: 40),

          /// 🌍 Globe
          AnimatedBuilder(
            animation: _globeController,
            builder: (_, __) {
              return Column(
                children: [
                  CustomPaint(
                    size: const Size(260, 260),
                    painter: EarthGlobePainter(
                      t: _globeController.value,
                      isDark: widget.isDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          /// 🌐 Language pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: widget.langPills
                .map(
                  (p) => LanguagePill(
                    label: p.toString(),
                    isDark: widget.isDark,
                    type: '',
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
