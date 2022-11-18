import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';
// class SkillFlatConverter implements JsonConverter<Skill, Map<String, dynamic>> {
//   const SkillFlatConverter();

//   @override
//   Skill fromJson(Map<String, dynamic> json) => Skill.fromJson(json);

//   @override
//   Map<String, dynamic> toJson(Skill data) => {"id": data.id ?? ''};
// }

@freezed
class User with _$User {
  const factory User({
    required String email,
    @Default(false) bool isAdmin,
    // @SkillFlatConverter() List<Skill>? skills,
  }) = _User;

  factory User.fromJson(Map<String, Object?> json) => _$UserFromJson(json);
}
