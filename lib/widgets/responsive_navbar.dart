import 'package:flutter/material.dart';
import 'package:tds_voice_agent/core/agni_colors.dart';
import 'package:tds_voice_agent/routing/app_routes.dart';
import 'package:tds_voice_agent/theme/app_typography.dart';

class ResponsiveNavbar extends StatelessWidget {
  final bool isDark;
  final List<String> navItems;
  final VoidCallback onToggleTheme;
  final VoidCallback? onMenuTap;

  /// Pushes a named [AppRoutes] path (e.g. [AppRoutes.solutions]).
  final void Function(String route)? onOpenRoute;

  const ResponsiveNavbar({
    super.key,
    required this.isDark,
    required this.navItems,
    required this.onToggleTheme,
    this.onMenuTap,
    this.onOpenRoute,
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
            final route = AppRoutes.pathForNavLabel(item);
            return Padding(
              padding: const EdgeInsets.only(left: 32),
              child: InkWell(
                onTap: route != null && onOpenRoute != null
                    ? () => onOpenRoute!(route)
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text(
                    item,
                    style: AppTypography.navItem(color: _text2Color(context)),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(width: 32),
        _ctaButton(context),
        const SizedBox(width: 12),
        _themeToggle(),
      ],
    );
  }

  // 📱 Mobile Navbar
  Widget _buildMobile(BuildContext context) {
    void openMenu() {
      if (onMenuTap != null) {
        onMenuTap!();
      } else {
        Scaffold.maybeOf(context)?.openDrawer();
      }
    }

    return Row(
      children: [
        _logo(),
        const Spacer(),
        _themeToggle(),
        const SizedBox(width: 4),
        IconButton(
          icon: Icon(Icons.menu_rounded, color: _text2Color(context)),
          tooltip: 'Menu',
          onPressed: openMenu,
        ),
      ],
    );
  }

  // 🎨 Logo
  Widget _logo() {
    return Text(
      'Technodysis',
      style: AppTypography.brandWordmark(
        color: isDark ? AgniColors.darkText : AgniColors.lightOceanDeep,
      ),
    );
  }

  // 🚀 CTA Button
  Widget _ctaButton(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        gradient: AgniColors.grad,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        'Contact sales →',
        style: AppTypography.ctaCompact(color: Colors.white),
      ),
    );

    if (onOpenRoute == null) return child;

    return InkWell(
      onTap: () => onOpenRoute!(AppRoutes.contactSales),
      borderRadius: BorderRadius.circular(24),
      child: child,
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
