import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/signup_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class LoginPage extends StatelessWidget {
  static const routeName = '/LoginPage';
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login page"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: "Password"),
          ),
          ElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationService>()
                    .signIn(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    )
                    .then((value) {
                  User? user = FirebaseAuth.instance.currentUser;
                  if (user!.emailVerified == false) {
                    FirebaseAuth.instance.signOut();
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text("Email not verified"),
                            content: const Text(
                                "Check your inbox to verify your account"),
                            actions: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Okay!"))
                            ],
                          );
                        });
                  } else {
                    print("Hello");
                    Navigator.pushNamed(context, HomePage.routeName);
                  }
                });
              },
              child: const Text("Sign in")),
          TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SignUpPage()),
                );
              },
              child: const Text("Sign up"))
        ],
      ),
    );
  }
}
