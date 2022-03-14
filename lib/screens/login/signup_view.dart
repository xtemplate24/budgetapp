import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/screens/login/login_error_handler.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SignUpPage extends StatelessWidget {
  static const routeName = '/SignUpPage';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController1 = TextEditingController();
  final TextEditingController passwordController2 = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign up page"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            controller: passwordController1,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          TextField(
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            controller: passwordController2,
            decoration: const InputDecoration(
                labelText: "Enter password again, just in case"),
          ),
          ElevatedButton(
              onPressed: () async {
                if (passwordController1.text != passwordController2.text) {
                  showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialogOneOption(
                            title: "Passwords don't match",
                            content: "Let's try that again",
                            buttonText: "Okay!",
                            context: context);
                      });
                } else {
                  await context
                      .read<AuthenticationService>()
                      .signUp(
                        email: emailController.text.trim(),
                        password: passwordController1.text.trim(),
                      )
                      .then((value) async {
                    print(value);
                    LoginErrorHandler().errorMessage(value, context);
                    User? user = FirebaseAuth.instance.currentUser;
                    print(user!.email);

                    if (user != null && !user.emailVerified) {
                      await user
                          .sendEmailVerification()
                          .then((value) => showDialog(
                              context: context,
                              builder: (context) {
                                FirebaseAuth.instance.signOut();
                                return AlertDialogOneOption(
                                    title: "Verification email sent!",
                                    content:
                                        "Check your inbox to verify your account",
                                    buttonText: "Okay!",
                                    context: context);
                              }).then((value) => Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (BuildContext context) => LoginPage(),
                              ),
                              (route) => false)));
                    }
                    //Navigator.pop(context);
                  });
                }
              },
              child: Text("Sign up")),
        ],
      ),
    );
  }
}
