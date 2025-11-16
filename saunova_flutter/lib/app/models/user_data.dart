import 'package:saunova/app/models/session.dart';

import 'badge.dart';
import 'friend.dart';

const _noChange = Object();

class UserData {
  final int age;
  final String gender;
  final List<String> goals;
  final int height;
  final int weight;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final List<Session> sessions;
  final String? image;
  final List<Badge> badges;
  final List<Friend> friends;

  UserData({
    required this.age,
    required this.gender,
    required this.goals,
    required this.height,
    required this.weight,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.sessions,
    this.image,
    required this.badges,
    required this.friends,
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    return UserData(
      age: userJson['age'] as int,
      gender: userJson['gender'] as String,
      goals: List<String>.from(userJson['goals'] as List<dynamic>),
      height: userJson['height'] as int,
      weight: userJson['weight'] as int,
      onboardingCompleted: userJson['onboardingCompleted'] as bool,
      createdAt: DateTime.parse(userJson['createdAt'] as String),
      sessions: (json['sessions'] as List<dynamic>)
          .map(
            (sessionJson) =>
                Session.fromJson(sessionJson as Map<String, dynamic>),
          )
          .toList(),
      image: userJson['image'] as String?,
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map(
                (badgeJson) =>
                    Badge.fromJson(badgeJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
      friends:
          (json['friends'] as List<dynamic>?)
              ?.map(
                (friendJson) =>
                    Friend.fromJson(friendJson as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  factory UserData.error() {
    return UserData(
      age: 0,
      gender: '',
      goals: [],
      height: 0,
      weight: 0,
      onboardingCompleted: false,
      createdAt: DateTime.now(),
      sessions: [],
      badges: [],
      friends: [],
    );
  }

  factory UserData.empty(String id) {
    return UserData(
      age: 0,
      gender: '',
      goals: [],
      height: 0,
      weight: 0,
      onboardingCompleted: false,
      createdAt: DateTime.now(),
      sessions: [],
      badges: [],
      friends: [],
    );
  }

  UserData copyWith({
    int? age,
    String? gender,
    List<String>? goals,
    int? height,
    int? weight,
    bool? onboardingCompleted,
    DateTime? createdAt,
    List<Session>? sessions,
    Object? image = _noChange,
    List<Badge>? badges,
    List<Friend>? friends,
  }) {
    return UserData(
      age: age ?? this.age,
      gender: gender ?? this.gender,
      goals: goals ?? this.goals,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      sessions: sessions ?? this.sessions,
      image: identical(image, _noChange) ? this.image : image as String?,
      badges: badges ?? this.badges,
      friends: friends ?? this.friends,
    );
  }

  List<Session> getLatestSessions(int count) {
    final sortedSessions = List<Session>.from(sessions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sortedSessions.take(count).toList();
  }
}
