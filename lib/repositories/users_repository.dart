import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import '../provider/pocketbase_provider.dart';
import '../models/user_model.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(userServiceProvider));
});

class UsersRepository {
  final RecordService userService;

  const UsersRepository(
    this.userService,
  );

  Future<List<User>> getAll() async {
    return (await userService.getFullList())
        .map((user) => User(
              username: user.data['username'],
              name: user.data['name'],
              isAdmin: false,
            ))
        .toList();
  }
}
