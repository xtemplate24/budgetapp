import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/screens/login/login_error_handler.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/src/provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  static const routeName = '/ForgotPasswordPage';
  @override
  ForgotPasswordPageState createState() => ForgotPasswordPageState();
}

class ForgotPasswordPageState extends State<ForgotPasswordPage> {
  bool _signInDisabled = true;
  void changeSignInDisabled() {
    if (emailController.text.isEmpty == false) {
      setState(() {
        _signInDisabled = false;
      });
    } else {
      setState(() {
        _signInDisabled = true;
      });
    }
  }

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
            onChanged: (value) => {changeSignInDisabled()},
            controller: emailController,
            decoration: InputDecoration(labelText: "Email"),
          ),
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary:
                    _signInDisabled ? Colors.grey : ColorTheme().gradientGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5.0,
              ),
              onPressed: () async {
                if (_signInDisabled) {
                  null;
                } else {
                  await context
                      .read<AuthenticationService>()
                      .forgotPassword(
                        email: emailController.text.trim(),
                      )
                      .then((value) async {
                    LoginErrorHandler().errorMessage(value, context);
                    showDialog(
                        context: context,
                        builder: (context) {
                          FirebaseAuth.instance.signOut();
                          return AlertDialogOneOption(
                              title: "Reset password email sent!!",
                              content:
                                  "Check your inbox to reset your password",
                              buttonText: "Okay!",
                              context: context);
                        }).then((value) => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => LoginPage(),
                        ),
                        (route) => false));
                  });
                }
              },
              child: const Text("Reset password")),
        ],
      ),
    );
  }
}
