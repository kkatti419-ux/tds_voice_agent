import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tds_voice_agent/routing/app_routes.dart';
import 'package:tds_voice_agent/theme/app_theme.dart';
import 'package:tds_voice_agent/view/placeholder_page.dart';
import 'view/voice_screen.dart';
import 'viewmodel/voice_viewmodel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => VoiceViewModel(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: const VoiceScreen(),
        routes: {
          AppRoutes.solutions: (_) => const PlaceholderPage(title: 'Solutions'),
          AppRoutes.industries: (_) =>
              const PlaceholderPage(title: 'Industries'),
          AppRoutes.platform: (_) => const PlaceholderPage(title: 'Platform'),
          AppRoutes.pricing: (_) => const PlaceholderPage(title: 'Pricing'),
          AppRoutes.contactSales: (_) =>
              const PlaceholderPage(title: 'Contact sales'),
          AppRoutes.talkToExpert: (_) =>
              const PlaceholderPage(title: 'Talk to an expert'),
          AppRoutes.seeHowItWorks: (_) =>
              const PlaceholderPage(title: 'See how it works'),
          AppRoutes.technodysis: (_) =>
              const PlaceholderPage(title: 'Technodysis'),
          AppRoutes.nityaAi: (_) => const PlaceholderPage(title: 'Nitya.AI'),
          AppRoutes.careers: (_) => const PlaceholderPage(title: 'Careers'),
          AppRoutes.linkedin: (_) => const PlaceholderPage(title: 'LinkedIn'),
          AppRoutes.twitter: (_) => const PlaceholderPage(title: 'Twitter'),
          AppRoutes.contactEmail: (_) => const PlaceholderPage(
                title: 'hello@technodysis.com',
              ),
        },
      ),
    );
  }
}
