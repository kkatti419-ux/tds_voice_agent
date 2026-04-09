/// Named routes for in-app navigation (placeholders until real screens exist).
abstract final class AppRoutes {
  static const String home = '/';

  // App bar / drawer (matches [AgniContent.navItems])
  static const String solutions = '/solutions';
  static const String industries = '/industries';
  static const String platform = '/platform';
  static const String pricing = '/pricing';

  static const String contactSales = '/contact-sales';

  // Hero CTAs
  static const String talkToExpert = '/talk-to-expert';
  static const String seeHowItWorks = '/see-how-it-works';

  // Footer
  static const String technodysis = '/technodysis';
  static const String nityaAi = '/nitya-ai';
  static const String careers = '/careers';
  static const String linkedin = '/linkedin';
  static const String twitter = '/twitter';
  static const String contactEmail = '/hello-technodysis';

  /// Maps navbar label from content to [AppRoutes] path.
  static String? pathForNavLabel(String label) {
    switch (label) {
      case 'Solutions':
        return solutions;
      case 'Industries':
        return industries;
      case 'Platform':
        return platform;
      case 'Pricing':
        return pricing;
      default:
        return null;
    }
  }

  /// Maps footer link labels to routes.
  static String? pathForFooterLink(String link) {
    switch (link) {
      case 'Technodysis':
        return technodysis;
      case 'Nitya.AI':
        return nityaAi;
      case 'Careers':
        return careers;
      case 'LinkedIn':
        return linkedin;
      case 'Twitter':
        return twitter;
      case 'hello@technodysis.com':
        return contactEmail;
      default:
        return null;
    }
  }
}
