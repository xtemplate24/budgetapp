import 'package:budgetapp/components/standard_alert.dart';
import 'package:flutter/material.dart';

class LoginErrorHandler {

  AlertDialogOneOption errorMessage(value, context) {
    switch (value) {
      case "user-not-found":
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialogOneOption(
                  title: "User not found",
                  content:
                      'Hmmm... it seems this email is not registered with us. Please try again!',
                  buttonText: "Okay!",
                  context: context);
            });
        break;
      case "wrong-password":
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialogOneOption(
                  title: "Incorrect password",
                  content: "Oops, let's try that again",
                  buttonText: "Okay!",
                  context: context);
            });
        break;
      case "invalid-email":
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialogOneOption(
                  title: "Invalid email",
                  content: "That email doesn't look right, please try again",
                  buttonText: "Okay!",
                  context: context);
            });
        break;
    }
    return AlertDialogOneOption(
        title: "Oops",
        content: "Something went wrong",
        buttonText: "Try again",
        context: context);
  }
}
