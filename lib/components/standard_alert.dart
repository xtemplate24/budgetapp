import 'package:budgetapp/components/color_theme.dart';
import 'package:flutter/material.dart';


class AlertDialogTwoOptions extends StatelessWidget {

  const AlertDialogTwoOptions({
    Key? key,
    required this.title,
    required this.content,
    required this.buttonTextA,
    required this.buttonTextB,
    required this.context,
  }) : super(key: key);

  final String title;
  final String content;
  final String buttonTextA;
  final String buttonTextB;
  final BuildContext context;
  final valueA = 0;
  final valueB = 1;

  @override
  Widget build(BuildContext context) {
    Widget actionButtonA = TextButton(
      child: Text(
        buttonTextA,
        style: TextStyle(fontSize: 17, color: ColorTheme().gradientGreen),
      ),
      onPressed: () async {
        Navigator.pop(context, valueA);
      },
    );
    Widget actionButtonB = TextButton(
      child: Text(
        buttonTextB,
        style: TextStyle(fontSize: 17, color: ColorTheme().gradientGreen),
      ),
      onPressed: () async {
        Navigator.pop(context, valueB);
      },
    );

    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16))),
          title: Text(
            title,
            style: TextStyle(fontSize: 17, color: ColorTheme().gradientPurple),
          ),
          content: Text(
            content,
            style: TextStyle(fontSize: 17, color: Colors.grey[700]),
          ),
          actions: [actionButtonA, actionButtonB]),
    );
  }
}

class AlertDialogOneOption extends StatelessWidget {
  const AlertDialogOneOption({
    Key? key,
    required this.title,
    required this.content,
    required this.buttonText,
    required this.context,
  }) : super(key: key);

  final String title;
  final String content;
  final String buttonText;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    Widget actionButton = TextButton(
      child: Text(
        buttonText,
        style: TextStyle(fontSize: 17, color: ColorTheme().gradientGreen),
      ),
      onPressed: () async {
        Navigator.pop(context);
      },
    );
    return AlertDialog(
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16))),
        title: Text(
          title,
          style: TextStyle(fontSize: 17, color: ColorTheme().gradientPurple),
        ),
        content: Text(
          content,
          style: TextStyle(fontSize: 17, color: Colors.grey[700]),
        ),
        actions: [actionButton]);
  }
}
