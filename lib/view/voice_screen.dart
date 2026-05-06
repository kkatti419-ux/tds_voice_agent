import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/model/agni_content.dart';
import 'package:tds_voice_agent/routing/app_routes.dart';
import 'package:tds_voice_agent/theme/theme_mode_notifier.dart';
import 'package:tds_voice_agent/widgets/earth/earth_section.dart'
    show EarthSection, LangItem;
import 'package:tds_voice_agent/widgets/feature/features_section.dart';
import 'package:tds_voice_agent/widgets/footer_section.dart';
import 'package:tds_voice_agent/widgets/hero_section.dart';
import 'package:tds_voice_agent/widgets/marquee/marquee_section.dart';
import 'package:tds_voice_agent/widgets/contact_form_dialog.dart';
import 'package:tds_voice_agent/widgets/responsive_navbar.dart';
import 'package:tds_voice_agent/widgets/comparisons_section.dart';
import 'package:tds_voice_agent/widgets/background_painters.dart';
import 'package:tds_voice_agent/widgets/stats/stats_section.dart';

import '../core/agni_colors.dart';
import 'package:tds_voice_agent/data/datasources/local_content_data_source.dart';
import '../theme/app_typography.dart';

class VoiceScreen extends StatelessWidget {
  const VoiceScreen({super.key});

  static final _content = LocalContentDataSource().load();

  @override
  Widget build(BuildContext context) {
    final isDark =
        context.watch<ThemeModeNotifier>().themeMode == ThemeMode.dark;
    return AgniLandingPage(
      content: _content,
      isDark: isDark,
      onToggleTheme: () => context.read<ThemeModeNotifier>().toggle(),
    );
  }
}

// Main Landing Page
class AgniLandingPage extends StatefulWidget {
  final AgniContent content;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const AgniLandingPage({
    super.key,
    required this.content,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<AgniLandingPage> createState() => _AgniLandingPageState();
}

class _AgniLandingPageState extends State<AgniLandingPage>
    with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _revealKeys = List.generate(5, (_) => GlobalKey());
  final List<bool> _revealed = List.filled(5, false);
  late AnimationController _globeController;
  late AnimationController _marqueeController;

  @override
  void initState() {
    super.initState();

    _globeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _marqueeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();

    _scrollController.addListener(_checkReveal);

    // Initial reveal check after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkReveal());
  }

  void _checkReveal() {
    for (int i = 0; i < _revealKeys.length; i++) {
      if (_revealed[i]) continue;
      final ctx = _revealKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final pos = box.localToGlobal(Offset.zero);
      final screenH = MediaQuery.of(context).size.height;
      if (pos.dy < screenH * 0.88) {
        setState(() => _revealed[i] = true);
      }
    }
  }

  @override
  void dispose() {
    _globeController.dispose();
    _marqueeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  AgniContent get content => widget.content;
  bool get isDark => widget.isDark;

  Color get bgColor => isDark ? AgniColors.darkBg : AgniColors.lightBg;
  Color get textColor => isDark ? AgniColors.darkText : AgniColors.lightText;
  Color get text2Color => isDark ? AgniColors.darkText2 : AgniColors.lightText2;
  Color get text3Color => isDark ? AgniColors.darkText3 : AgniColors.lightText3;
  Gradient get gradText =>
      isDark ? AgniColors.gradText : AgniColors.gradTextLight;

  Widget _buildDrawer(BuildContext context) {
    final borderColor = isDark
        ? AgniColors.darkBorder.withOpacity(0.12)
        : AgniColors.oceanMid.withOpacity(0.12);

    return Drawer(
      backgroundColor: bgColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Technodysis',
                      style: AppTypography.brandWordmark(color: text2Color),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: text2Color,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (final item in content.navItems)
                    ListTile(
                      title: Text(
                        item,
                        style: AppTypography.navItem(color: text2Color),
                      ),
                      onTap: () {
                        Navigator.of(context).pop();
                        final route = AppRoutes.pathForNavLabel(item);
                        if (route != null) {
                          Navigator.of(context).pushNamed(route);
                        }
                      },
                    ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          showContactFormDialog(
                            context,
                            isDark: isDark,
                            showSalesOfficeAddress: true,
                          );
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient: AgniColors.grad,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Contact sales →',
                            style: AppTypography.ctaCompact(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),
            ListTile(
              leading: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? AgniColors.oceanBright : AgniColors.oceanMid,
              ),
              title: Text(
                isDark ? 'Light mode' : 'Dark mode',
                style: AppTypography.navItem(color: text2Color),
              ),
              onTap: () {
                Navigator.of(context).pop();
                widget.onToggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          // Background layer
          _buildBackground(),
          // Content: fixed top bar, scroll the rest
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SafeArea(
                bottom: false,
                child: ResponsiveNavbar(
                  isDark: isDark,
                  navItems: content.navItems,
                  onToggleTheme: widget.onToggleTheme,
                  onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
                  onContactSales: () => showContactFormDialog(
                    context,
                    isDark: isDark,
                    showSalesOfficeAddress: true,
                  ),
                  onOpenRoute: (route) {
                    Navigator.of(context).pushNamed(route);
                  },
                ),
              ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    _checkReveal();
                    return false;
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      children: [
                        // _buildHero(),
                        HeroSection(content: content, isDark: isDark),
                        // _buildMarquee(),
                        MarqueeSection(
                          items: content.marqueeItems,
                          isDark: isDark,
                        ),
                        // _buildStats(),
                        StatsSection(isDark: isDark, stats: content.stats),
                        FeaturesSection(content: content, isDark: isDark),
                        ComparisonsSection(
                          comparisons: content.comparisons,
                          isDark: isDark,
                          textColor: textColor,
                          text2Color: text2Color,
                          text3Color: text3Color,
                        ),
                        EarthSection(
                          langPills: content.langPills
                              .map((p) => LangItem(p.label, p.type))
                              .toList(),
                          isDark: isDark,
                        ),
                        // CTABanner(isDark: isDark),
                        // _buildFooter(),
                        FooterSection(
                          isDark: isDark,
                          onOpenRoute: (route) {
                            Navigator.of(context).pushNamed(route);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Background ───────────────────────────────────────────────────────────

  Widget _buildBackground() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _globeController,
        builder: (_, _) => CustomPaint(
          painter: BackgroundPainter(isDark: isDark, t: _globeController.value),
        ),
      ),
    );
  }
}
