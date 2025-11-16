import 'badge.dart';

class Friend {
  final String id;
  final String name;
  final String? image;
  final String status; // 'in sauna', 'offline', 'online'
  final List<Badge> badges;
  Friend({
    required this.id,
    required this.name,
    this.image,
    required this.status,
    required this.badges,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String?,
      status: json['status'] as String,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map(
                (badgeJson) =>
                    Badge.fromJson(badgeJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}
