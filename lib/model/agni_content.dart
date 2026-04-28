// Landing / marketing content models (stats, features, comparisons, hero meta).

class StatItem {
  final String value;
  final String description;

  const StatItem({required this.value, required this.description});
}

class FeatureItem {
  final String icon;
  final String title;
  final String description;
  final String stat;

  const FeatureItem(this.icon, this.title, this.description, this.stat);
}

class ComparisonCardData {
  final bool isOurs;
  final String badge;
  final String headline;
  final List<String> items;

  const ComparisonCardData({
    required this.isOurs,
    required this.badge,
    required this.headline,
    required this.items,
  });
}

class LangPill {
  final String label;

  /// '', 'ocean', 'forest'
  final String type;

  const LangPill(this.label, this.type);
}

class FloatingCardData {
  final String stat;
  final String label;
  final double delayFactor;

  const FloatingCardData(this.stat, this.label, this.delayFactor);
}

class AgniContent {
  final List<String> navItems;
  final List<String> marqueeItems;
  final List<String> heroLangs;
  final List<String> tickerTags;
  final List<StatItem> stats;
  final List<FeatureItem> features;
  final List<ComparisonCardData> comparisons;
  final List<LangPill> langPills;
  final List<FloatingCardData> floatingCards;

  final String heroBadge;
  final String heroTitleLine1;
  final String heroTitlePrefix;
  final String heroTitleAccent;
  final String heroDescription;

  final String featuresSectionTag;
  final String featuresSectionTitle;
  final String featuresSectionBlurb;

  const AgniContent({
    required this.navItems,
    required this.marqueeItems,
    required this.heroLangs,
    required this.tickerTags,
    required this.stats,
    required this.features,
    required this.comparisons,
    required this.langPills,
    required this.floatingCards,
    required this.heroBadge,
    required this.heroTitleLine1,
    required this.heroTitlePrefix,
    required this.heroTitleAccent,
    required this.heroDescription,
    required this.featuresSectionTag,
    required this.featuresSectionTitle,
    required this.featuresSectionBlurb,
  });
}
