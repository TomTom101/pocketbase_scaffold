import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';

import 'provider/pocketbase_provider.dart';
import 'auth_local_storage.dart';
import 'models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final User user;

  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  final String? message;

  const Unauthenticated({this.message});
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authStorage = AuthLocalStorage(ref.watch(sharedPreferencesProvider));
  return AuthNotifier(ref.watch(pocketBaseProvider), authStorage);
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(PocketBase client, this.authLocalStorage)
      : userService = client.collection("users"),
        authStore = client.authStore,
        super(const Unauthenticated()) {
    authWithToken();
  }

  final RecordService userService;
  final AuthStore authStore;
  final AuthLocalStorage authLocalStorage;

  bool get isAuthenticated => state is Authenticated;
  bool get isLoading => state is AuthLoading;

  Future<void> logout() async {
    authStore.clear();
    authLocalStorage.clear();
    state = const Unauthenticated();
  }

  void authWithToken() {
    final tokenModel = authLocalStorage.loadAuthRecord();
    if (tokenModel != null) {
      RecordModel model = RecordModel.fromJson(tokenModel);
      authStore.save(tokenModel['token'], model);

      final user = User.fromJson(tokenModel['record']);
      state = Authenticated(user);
    }
  }

  Future<void> login(String email, String password) async {
    state = AuthLoading();
    try {
      final result = await userService.authWithPassword(email, password);
      if (result.record != null) {
        final user = User(
          email: result.record?.data['email'],
          isAdmin: result.record?.data['admin'],
        );
        authStore.save(result.token, result.record);
        await authLocalStorage.saveAuthRecord(result);
        state = Authenticated(user);
      }
    } on ClientException catch (e) {
      state = Unauthenticated(message: e.response['message']);
    }
  }
}
