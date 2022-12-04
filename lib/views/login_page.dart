import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../auth.dart';
import '../provider/pocketbase_provider.dart';

final isOscureTextProvider = StateProvider<bool>((ref) {
  return true;
});

final formKey = GlobalKey<FormBuilderState>();

final authServicesProvider = FutureProvider(
    (ref) async => await ref.watch(userServiceProvider).listAuthMethods());

extension StringCasingExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({
    this.authCode,
    super.key,
  });

  static String get routeName => 'login';
  static String get routeLocation => '/$routeName';
  final String? authCode;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  @override
  void initState() {
    if (widget.authCode != null) {
      ref.read(authProvider.notifier).authWithOAuth2(widget.authCode!);
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authProviders = ref.watch(authServicesProvider);
    final isOscureText = ref.watch(isOscureTextProvider);
    final screenSize = MediaQuery.of(context).size;

    void signIn() async {
      final isValidated = formKey.currentState?.saveAndValidate() ?? false;
      if (!isValidated) {
        return;
      }

      final email = formKey.currentState?.value['email'];
      final password = formKey.currentState?.value['password'];
      await ref.read(authProvider.notifier).authWithPassword(email, password);
    }

    ref.listen(authProvider, (_, state) {
      if (state is Unauthenticated) {
        if (state.message == null) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(state.message!)));
      }
    });

    return Scaffold(
      appBar: null,
      body: (widget.authCode != null)
          ? const Center(child: Text("redirecting …"))
          : Center(
              child: SizedBox(
                width: screenSize.width / 3,
                child: FormBuilder(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 10),
                      FormBuilderTextField(
                        name: "email",
                        initialValue: "user",
                        decoration: const InputDecoration(
                          label: Text("E-mail or username"),
                        ),
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      FormBuilderTextField(
                        name: "password",
                        initialValue: "user1234",
                        decoration: InputDecoration(
                          label: const Text("Password"),
                          suffixIcon: IconButton(
                            onPressed: () => ref
                                .read(isOscureTextProvider.notifier)
                                .update((state) => !isOscureText),
                            icon: !isOscureText
                                ? const Icon(Icons.visibility)
                                : const Icon(Icons.visibility_off),
                          ),
                        ),
                        obscureText: isOscureText,
                        validator: FormBuilderValidators.compose([
                          FormBuilderValidators.required(),
                          FormBuilderValidators.minLength(8),
                        ]),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        height: 40,
                        width: screenSize.width,
                        child: (authProvider.notifier is AuthLoading)
                            ? const ElevatedButton(
                                onPressed: null,
                                child: LinearProgressIndicator(),
                              )
                            : ElevatedButton(
                                onPressed: signIn,
                                child: const Text("Log in"),
                              ),
                      ),
                      const SizedBox(height: 40),
                      authProviders.when(
                        data: (data) => Column(
                          children: data.authProviders
                              .map((provider) => SignInButton(
                                    Buttons.GoogleDark,
                                    onPressed: () => ref
                                        .read(authProvider.notifier)
                                        .loginProvider(provider),
                                  ))
                              .toList(),
                        ),
                        error: (error, stackTrace) => Text(error.toString()),
                        loading: () => const LinearProgressIndicator(),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
