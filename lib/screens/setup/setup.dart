import 'package:budgetapp/components/color_theme.dart';
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

class SetupPage extends StatefulWidget {
  static const routeName = '/SetupPage';
  @override
  State<SetupPage> createState() => SetupPageState();
}

class SetupPageState extends State<SetupPage> {
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');
    final TextEditingController budgetInputController = TextEditingController();
    PageController pageController = PageController(
      initialPage: 0,
    );

    print("in setup page");

    final pages = List.generate(
      2,
      ((index) => index == 0
          ? Container(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                  TextField(
                    keyboardType: TextInputType.number,
                    controller: budgetInputController,
                    decoration:
                        const InputDecoration(labelText: "Monthly income"),
                  ),
                  const Text("This can be changed later too"),
                ]))
          : Container(
              child: Text("Test"),
            )),
    );

    Widget nextButton = ElevatedButton(
      child: Padding(
        padding: EdgeInsets.fromLTRB(width! * 0.2, 10, height! * 0.3, 10),
        child: Text(
          'Next',
          style: TextStyle(fontSize: 17, color: Colors.white),
        ),
      ),
      style: ElevatedButton.styleFrom(
        primary: ColorTheme().gradientPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
        ),
        elevation: 5.0,
      ),
      onPressed: () async {
        
        if (pageController.page == 0) {
          await FirebaseInteractions.updateIncome(
            users, user!.uid, int.parse(budgetInputController.text.trim()));
          await pageController.nextPage(
              duration: Duration(milliseconds: 200), curve: Curves.easeIn);
        } else {
          Navigator.of(context, rootNavigator: true).pop();
        }
      },
    );



    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("Setup page"),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Container(
              height: height! * 0.5,
              child: PageView.builder(
                physics: NeverScrollableScrollPhysics(),
                itemCount: pages.length,
                controller: pageController,
                itemBuilder: (_, index) {
                  return pages[index % pages.length];
                },
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: SmoothPageIndicator(
                  controller: pageController,
                  count: pages.length,
                  effect: ScrollingDotsEffect(
                    activeStrokeWidth: 2.6,
                    activeDotScale: 1.3,
                    maxVisibleDots: 5,
                    radius: 8,
                    spacing: 10,
                    dotHeight: 10,
                    dotWidth: 10,
                    activeDotColor: ColorTheme().gradientGreen,
                  )),
            ),
            nextButton,
          ],
        ),
      ),
    );
  }
}
