import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';

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
  User get me => (state as Authenticated).user;

  Future<void> logout() async {
    authStore.clear();
    authLocalStorage.clear();
    state = const Unauthenticated();
  }

  void authWithToken() {
    final tokenModel = authLocalStorage.loadJsonRecord("model");
    if (tokenModel != null) {
      RecordModel model = RecordModel.fromJson(tokenModel);
      authStore.save(tokenModel['token'], model);

      final user = User.fromJson(tokenModel['record']);
      state = Authenticated(user);
    }
  }

  Future<void> authWithPassword(String email, String password) async {
    state = AuthLoading();
    try {
      final result = await userService.authWithPassword(email, password);
      if (result.record != null) {
        final user = User(
          id: result.record?.id,
          username: result.record?.data['username'],
          name: result.record?.data['name'],
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

  Future<void> authWithOAuth2(String code) async {
    try {
      final provider = authLocalStorage.loadJsonRecord("provider");
      final result = await userService.authWithOAuth2(
          provider!['name'], code, provider['codeVerifier'], redirectUrl());
      final user = User(
        id: result.record?.id,
        username: result.record?.data['username'],
        name: result.record?.data['name'],
        isAdmin: false,
      );
      authStore.save(result.token, result.record);
      await authLocalStorage.saveAuthRecord(result);
      state = Authenticated(user);
    } on ClientException catch (e) {
      state = Unauthenticated(message: e.response['message']);
    }
  }

  String redirectUrl() {
    final uri = Uri.parse(Uri.base.toString());
    print("Host: ${uri.host}");
    return "${uri.scheme}://${uri.host}:${uri.port}/login";
  }

  Future<void> loginProvider(AuthMethodProvider provider) async {
    state = AuthLoading();
    final url = Uri.parse('${provider.authUrl}${redirectUrl()}');
    await authLocalStorage.saveProviderRecord(provider);
    await launchUrl(url, webOnlyWindowName: "_self");
  }
}
