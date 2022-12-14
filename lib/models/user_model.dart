import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'pocketbase_model.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class User extends BaseModel with _$User {
  User._();
  factory User({
    String? id,
    required String username,
    required String name,
    @Default(false) bool isAdmin,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);

  String get displayName => name.isEmpty ? username : name;
}
