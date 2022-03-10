import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class ForgotPasswordPage extends StatelessWidget {
  static const routeName = '/ForgotPasswordPage';
  final TextEditingController emailController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot password page"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Email"),
          ),
          ElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationService>()
                    .forgotPassword(
                      email: emailController.text.trim(),
                    )
                    .then((value) async {
                  showDialog(
                      context: context,
                      builder: (context) {
                        FirebaseAuth.instance.signOut();
                        return verificationEmailSent(context);
                      });
                });
              },
              child: const Text("Sign up")),
        ],
      ),
    );
  }

  AlertDialog verificationEmailSent(context) {
    return AlertDialog(
      title: const Text("Reset password email sent!"),
      content: const Text("Check your inbox to reset your password!"),
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
