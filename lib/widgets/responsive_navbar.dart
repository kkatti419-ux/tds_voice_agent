import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';

class ResponsiveNavbar extends StatelessWidget {
  final bool isDark;
  final List<String> navItems;
  final VoidCallback onToggleTheme;
  final VoidCallback? onMenuTap;

  const ResponsiveNavbar({
    super.key,
    required this.isDark,
    required this.navItems,
    required this.onToggleTheme,
    this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final navBg = isDark
        ? const Color(0xFF030D1A).withOpacity(0.82)
        : const Color(0xFFDCEEF8).withOpacity(0.82);

    final borderColor = isDark
        ? AgniColors.darkBorder.withOpacity(0.12)
        : AgniColors.oceanMid.withOpacity(0.12);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width > 900 ? 52 : 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: navBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: width > 900 ? _buildDesktop(context) : _buildMobile(context),
    );
  }

  // 💻 Desktop Navbar
  Widget _buildDesktop(BuildContext context) {
    return Row(
      children: [
        _logo(),
        const Spacer(),
        Row(
          children: navItems.map((item) {
            return Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(
                item,
                style: TextStyle(
                  color: _text2Color(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 32),
        _ctaButton(),
        const SizedBox(width: 12),
        _themeToggle(),
      ],
    );
  }

  // 📱 Mobile Navbar
  Widget _buildMobile(BuildContext context) {
    return Row(
      children: [
        _logo(),
        const Spacer(),
        _themeToggle(),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onMenuTap,
          child: Icon(Icons.menu, color: _text2Color(context)),
        ),
      ],
    );
  }

  // 🎨 Logo
  Widget _logo() {
    return Text(
      'Technodysis.',
      style: GoogleFonts.playfairDisplay(
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  // 🚀 CTA Button
  Widget _ctaButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: AgniColors.grad,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Contact sales →',
        style: TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // 🌗 Theme Toggle
  Widget _themeToggle() {
    return GestureDetector(
      onTap: onToggleTheme,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? AgniColors.darkBorder.withOpacity(0.10)
              : AgniColors.oceanMid.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          isDark ? Icons.light_mode : Icons.dark_mode,
          size: 16,
          color: isDark ? AgniColors.oceanBright : AgniColors.oceanMid,
        ),
      ),
    );
  }

  Color _text2Color(BuildContext context) {
    return isDark ? Colors.white70 : Colors.black87;
  }
}
