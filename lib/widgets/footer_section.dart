import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FooterSection extends StatelessWidget {
  final bool isDark;

  const FooterSection({super.key, required this.isDark});

  Color get text3Color => isDark ? Colors.white60 : Colors.black54;

  Gradient get gradText =>
      const LinearGradient(colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)]);

  @override
  Widget build(BuildContext context) {
    final links = [
      'Technodysis',
      'Nitya.AI',
      'Careers',
      'LinkedIn',
      'Twitter',
      'hello@technodysis.com',
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF030A16).withOpacity(0.70)
            : Colors.white.withOpacity(0.42),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.blue.withOpacity(0.12)
                : Colors.blue.withOpacity(0.12),
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;

          return isMobile
              ? _buildMobileLayout(links)
              : _buildDesktopLayout(links);
        },
      ),
    );
  }

  // 💻 Desktop Layout
  Widget _buildDesktopLayout(List<String> links) {
    return Row(
      children: [
        _logo(),
        const Spacer(),
        Row(
          children: links
              .map(
                (link) => Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    link,
                    style: TextStyle(fontSize: 14, color: text3Color),
                  ),
                ),
              )
              .toList(),
        ),
        const Spacer(),
        _copyright(),
      ],
    );
  }

  // 📱 Mobile Layout (IMPORTANT)
  Widget _buildMobileLayout(List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _logo(),
        const SizedBox(height: 20),

        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: links
              .map(
                (link) => Text(
                  link,
                  style: TextStyle(fontSize: 14, color: text3Color),
                ),
              )
              .toList(),
        ),

        const SizedBox(height: 20),

        _copyright(),
      ],
    );
  }

  Widget _logo() {
    return ShaderMask(
      shaderCallback: (b) => gradText.createShader(b),
      child: Text(
        'Technodysis.',
        style: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _copyright() {
    return Text(
      '© 2026 Technodysis. All rights reserved.',
      style: TextStyle(fontSize: 12, color: text3Color),
      textAlign: TextAlign.center,
    );
  }
}
