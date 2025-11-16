class Badge {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int requirement;
  final String rarity;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.rarity,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      requirement: json['requirement'] as int,
      rarity: json['rarity'] as String,
    );
  }
}
