// ignore_for_file: prefer_const_constructors, prefer_null_aware_operators

import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/firebase_interactions/firebase_interactions.dart';
import 'package:budgetapp/screens/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SetIncomePage extends StatefulWidget {
  static const routeName = '/SetIncomePage';
  @override
  State<SetIncomePage> createState() => SetIncomePageState();
}

class SetIncomePageState extends State<SetIncomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;
  List<String>? categoryList;
  int? previousIncome;
  TextEditingController incomeInputController = TextEditingController(text: null);
  bool firstLaunch = true;

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;
  }

  Future getPreviousIncome(userDirectory) async {
     await userDirectory.get().then((val) {
      setState(() {
        incomeInputController.text = val.data()['income'].toString();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    print("in set income page hehe");
    DocumentReference userDirectory =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    if (firstLaunch) {
      getPreviousIncome(userDirectory);
      setState(() {
        firstLaunch = false;
      });
    }

    Widget nextButton =ElevatedButton(
      child: Padding(
        padding: EdgeInsets.fromLTRB(width! * 0.3, 15, width! * 0.3, 15),
        child: const Text(
          'Save',
          style: TextStyle(fontSize: 17, color: Colors.white),
        ),
      ),
      style: ElevatedButton.styleFrom(
        primary: ColorTheme().gradientGreen,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 5.0,
      ),
      onPressed: () async {
        await FirebaseInteractions.updateIncome(
                userDirectory, int.parse(incomeInputController.text.trim()))
            .then((value) {
          Navigator.pop(context);
        });
      },
    ); 

    return Scaffold(
      appBar: AppBar(
        title: const Text("Change Income Page"),
      ),
      body: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            TextFormField(
              keyboardType: TextInputType.number,
              controller: incomeInputController,
              decoration: const InputDecoration(labelText: "Monthly income"),
            ),
            nextButton,
          ],
        ),
      ),
    );
  }
}
