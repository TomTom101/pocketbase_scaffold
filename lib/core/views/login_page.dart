import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import '../auth.dart';

final isOscureTextProvider = StateProvider<bool>((ref) {
  return true;
});

final formKey = GlobalKey<FormBuilderState>();

class LoginPage extends ConsumerWidget {
  const LoginPage({super.key});
  static String get routeName => 'login';
  static String get routeLocation => '/$routeName';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void signIn() async {
      final isValidated = formKey.currentState?.saveAndValidate() ?? false;
      if (!isValidated) {
        return;
      }

      final email = formKey.currentState?.value['email'];
      final password = formKey.currentState?.value['password'];
      await ref.read(authProvider.notifier).login(email, password);
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

    return Scaffold(
      appBar: null,
      body: Center(
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
                    label: Text("E-mail or user name"),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
