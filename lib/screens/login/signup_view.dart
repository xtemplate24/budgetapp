import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class SignUpPage extends StatelessWidget {
  static const routeName = '/SignUpPage';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
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
            decoration: InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: passwordController,
            decoration: InputDecoration(labelText: "Password"),
          ),
          ElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationService>()
                    .signUp(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    )
                    .then((value) async {
                  print(value);
                  User? user = FirebaseAuth.instance.currentUser;
                  print(user!.email);

                  if (user != null && !user.emailVerified) {
                    await user
                        .sendEmailVerification()
                        .then((value) => showDialog(
                            context: context,
                            builder: (context) {
                              FirebaseAuth.instance.signOut();
                              return verificationEmailSent(context);
                            }));
                  }
                  //Navigator.pop(context);
                });
              },
              child: Text("Sign up")),
        ],
      ),
    );
  }

  AlertDialog verificationEmailSent(context) {
    return AlertDialog(
      title: const Text("Verification email sent!"),
      content: const Text("Check your inbox to verify your account"),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => LoginPage(),
                  ),
                  (route) => false);
            },
            child: Text("Okay!"))
      ],
    );
  }
}
