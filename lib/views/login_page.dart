import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class LoginPage extends ConsumerWidget {
  const LoginPage({
    this.authCode,
    super.key,
  });
  static String get routeName => 'login';
  static String get routeLocation => '/$routeName';

  final String? authCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authProviders = ref.watch(authServicesProvider);
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

    final screenSize = MediaQuery.of(context).size;
    final authState = ref.watch(authProvider);
    final isOscureText = ref.watch(isOscureTextProvider);

    if (authCode != null) {
      print(authCode);
      ref.read(authProvider.notifier).authWithOAuth2(authCode!);
    }

    return Scaffold(
      appBar: null,
      body: Center(
        child: SizedBox(
          width: screenSize.width / 3,
          child: authCode != null
              ? const Text("Logged in – redirecting …")
              : FormBuilder(
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
                            onPressed: () {
                              ref
                                  .read(isOscureTextProvider.notifier)
                                  .update((state) => !isOscureText);
                            },
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
                      Consumer(builder: (context, ref, _) {
                        if (authState is AuthLoading) {
                          return SizedBox(
                            height: 40,
                            width: screenSize.width,
                            child: const ElevatedButton(
                              onPressed: null,
                              child: LinearProgressIndicator(),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 40,
                          width: screenSize.width,
                          child: ElevatedButton(
                            onPressed: signIn,
                            child: const Text("Log in"),
                          ),
                        );
                      }),
                      const SizedBox(height: 40),
                      authProviders.when(
                        data: (data) => Column(
                          children: data.authProviders
                              .map((provider) => ElevatedButton(
                                    onPressed: () => ref
                                        .read(authProvider.notifier)
                                        .loginProvider(provider),
                                    child: Text(
                                        "Login with ${provider.name.toCapitalized()}"),
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
