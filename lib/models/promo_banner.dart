class PromoBanner {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String ctaRoute;
  final bool active;

  const PromoBanner({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.ctaRoute,
    required this.active,
  });

  factory PromoBanner.fromMap(Map<String, dynamic> map) {
    return PromoBanner(
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      ctaLabel: (map['cta_label'] as String?)?.isNotEmpty == true ? map['cta_label'] as String : 'J\'en profite',
      ctaRoute: (map['cta_route'] as String?)?.isNotEmpty == true ? map['cta_route'] as String : '/shop',
      active: map['active'] as bool? ?? false,
    );
  }
}
