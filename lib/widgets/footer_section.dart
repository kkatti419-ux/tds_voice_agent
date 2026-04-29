import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/core/open_external_url.dart';
import 'package:tds_voice_agent/routing/app_routes.dart';

class FooterSection extends StatelessWidget {
  final bool isDark;

  /// Pushes a named route for footer links (see [AppRoutes.pathForFooterLink]).
  final void Function(String route)? onOpenRoute;

  const FooterSection({
    super.key,
    required this.isDark,
    this.onOpenRoute,
  });

  Color get text3Color => isDark ? AgniColors.white60 : AgniColors.black54;

  Gradient get gradText =>
      const LinearGradient(colors: [Color(0xFF5B6CFF), Color(0xFF8E44AD)]);
 @override
  Widget build(BuildContext context) {
    final links = [
      'Technodysis',
      'Nitya.AI',
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
            : AgniColors.white.withOpacity(0.42),
        border: Border(
          top: BorderSide(
            color: AgniColors.oceanBright.withOpacity(0.12),
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
                  child: _footerLink(link),
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
              .map((link) => _footerLink(link))
              .toList(),
        ),

        const SizedBox(height: 20),

        _copyright(),
      ],
    );
  }

  Widget _footerLink(String link) {
    final style = TextStyle(fontSize: 14, color: text3Color);
    if (link == 'hello@technodysis.com') {
      return Text(link, style: style);
    }

    const externalLinks = <String, String>{
      'Technodysis': 'https://technodysis.com/',
      'Nitya.AI': 'https://nitya.ai/',
      'LinkedIn': 'https://in.linkedin.com/company/technodysis',
      'Twitter': 'https://x.com/Technodysis1',
    };
    final externalUrl = externalLinks[link];
    if (externalUrl != null) {
      return InkWell(
        onTap: () => openExternalUrlInNewTab(externalUrl),
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(link, style: style),
        ),
      );
    }

    final route = AppRoutes.pathForFooterLink(link);
    if (route == null || onOpenRoute == null) {
      return Text(link, style: style);
    }
    return InkWell(
      onTap: () => onOpenRoute!(route),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(link, style: style),
      ),
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
          color: AgniColors.white,
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
