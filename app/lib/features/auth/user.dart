import 'package:flutter/foundation.dart';

/// The signed-in account, as returned by the Auth Service.
@immutable
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
    );
  }

  final int id;
  final String name;
  final String email;

  /// UTC. Convert with `toLocal()` before showing it.
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  /// One or two uppercase letters for the avatar.
  String get initials {
    final List<String> parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    final String first = parts.first.substring(0, 1);
    final String last = parts.length > 1 ? parts.last.substring(0, 1) : '';
    return (first + last).toUpperCase();
  }

  @override
  bool operator ==(Object other) {
    return other is User &&
        other.id == id &&
        other.name == name &&
        other.email == email &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(id, name, email, createdAt);
}
