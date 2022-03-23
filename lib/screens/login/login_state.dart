import 'package:budgetapp/authentication/authentication_service.dart';
import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/forgot_password_view.dart';
import 'package:budgetapp/screens/login/login_error_handler.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:budgetapp/screens/login/signup_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _signInDisabled = true;
  bool _passwordVisible = false;
  void changeSignInDisabled() {
    if (emailController.text.isEmpty == false &&
        passwordController.text.isEmpty == false) {
      setState(() {
        _signInDisabled = false;
      });
    } else {
      setState(() {
        _signInDisabled = true;
      });
    }
  }

  @override
  void initState() {
    _passwordVisible = false;
  }

  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Login page"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextFormField(
            onChanged: (value) => {changeSignInDisabled()},
            controller: emailController,
            decoration: const InputDecoration(labelText: "Email"),
          ),
          TextFormField(
            obscureText: !_passwordVisible,
            enableSuggestions: false,
            autocorrect: false,
            onChanged: (value) => {changeSignInDisabled()},
            controller: passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              // Here is key idea
              suffixIcon: IconButton(
                icon: Icon(
                  // Based on passwordVisible state choose the icon
                  _passwordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Theme.of(context).primaryColorDark,
                ),
                onPressed: () {
                  // Update the state i.e. toogle the state of passwordVisible variable
                  setState(() {
                    _passwordVisible = !_passwordVisible;
                  });
                },
              ),
            ),
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
                      .signIn(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      )
                      .then(
                    (value) {
                      print(value);
                      LoginErrorHandler().errorMessage(value, context);
                      User? user = FirebaseAuth.instance.currentUser;
                      if (user!.emailVerified == false) {
                        FirebaseAuth.instance.signOut();
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialogOneOption(
                                  title: "Email not verified",
                                  content:
                                      "Check your inbox to verify your account",
                                  buttonText: "Okay",
                                  context: context);
                            });
                      } else {
                        print("Hello");
                        Navigator.pushNamed(context, HomePage.routeName);
                      }
                    },
                  );
                }
              },
              child: const Text("Sign in")),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SignUpPage()),
                    );
                  },
                  child: const Text("Sign up")),
              TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ForgotPasswordPage()),
                    );
                  },
                  child: const Text("Forgot password")),
            ],
          ),
        ],
      ),
    );
  }
}
