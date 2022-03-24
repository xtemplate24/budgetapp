// ignore_for_file: prefer_const_constructors

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

class SetupPage extends StatefulWidget {
  static const routeName = '/SetupPage';
  @override
  State<SetupPage> createState() => SetupPageState();
}

class SetupPageState extends State<SetupPage> {
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;
  List<String>? categoryList;
  List<String> suggestionList = ["Transport", "Food", "Groceries"];
  final categoryInputController = TextEditingController();
  List<TextEditingController> controllers = [];
  List<TextField> fields = [];
  List<Map<String, dynamic>> finalCategoryList = [];

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;
    categoryList = [];
  }

  void addToList(String categoryname) {
    categoryname = categoryname.trim().toLowerCase();
    final controller = TextEditingController();
    final field = TextField(
      keyboardType: TextInputType.number,
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: "budget per month",
      ),
    );
    setState(() {
      if (categoryList!.contains(categoryname)) {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialogOneOption(
                  title: "Oops",
                  content: "Category already added",
                  buttonText: "Okay",
                  context: context);
            });
      } else {
        categoryList!.add(categoryname);
        controllers.add(controller);
        fields.add(field);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference userDirectory =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);
    final TextEditingController budgetInputController = TextEditingController();
    PageController pageController = PageController(
      initialPage: 0,
    );

    print("in setup page");

    final pages = List.generate(
      2,
      ((index) => index == 0
          ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              TextField(
                keyboardType: TextInputType.number,
                controller: budgetInputController,
                decoration: const InputDecoration(labelText: "Monthly income"),
              ),
              const Text("This can be changed later too"),
            ])
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Select a few categories for your expenses"),
                Container(
                  height: height! * 0.4,
                  child: SingleChildScrollView(
                    child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: categoryList!.length,
                      itemBuilder: (BuildContext context, int index) {
                        return Dismissible(
                          onDismissed: ((direction) {
                            setState(() {
                              categoryList!.removeAt(index);
                              controllers.removeAt(index);
                              fields.removeAt(index);
                            });
                          }),
                          key: Key(categoryList![index]),
                          background: Container(color: Colors.red),
                          direction: DismissDirection.endToStart,
                          child: Container(
                            height: 50,
                            child: Row(children: [
                              Text(
                                categoryList![index],
                              ),
                              Expanded(child: fields[index]),
                            ]),
                          ),
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) =>
                          const Divider(),
                    ),
                  ),
                ),
                Container(
                  width: width! * 1,
                  height: height! * 0.2,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: suggestionList.length,
                        itemBuilder: (BuildContext context, int index) {
                          return TextButton(
                              child: Text(suggestionList[index]),
                              onPressed: () {
                                addToList(suggestionList[index]);
                                setState(() {
                                  suggestionList.removeAt(index);
                                });
                              });
                        }),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: categoryInputController,
                        decoration: const InputDecoration(
                            labelText: "Enter a custom category"),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          addToList(categoryInputController.text);
                          categoryInputController.clear();
                        },
                        child: Text("Add")),
                  ],
                ),
              ],
            )),
    );

    Widget nextButton = ElevatedButton(
      child: Padding(
        padding: EdgeInsets.fromLTRB(width! * 0.2, 10, height! * 0.3, 10),
        child: const Text(
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
              userDirectory, int.parse(budgetInputController.text.trim()));
          await pageController.nextPage(
              duration: Duration(milliseconds: 200), curve: Curves.easeIn);
        } else {
          for (int i = 0; i < categoryList!.length; i++) {
            Map<String, dynamic> tempMap = {
              "name": categoryList![i],
              "amount": controllers[i].text.isEmpty
                  ? 0
                  : int.parse(controllers[i].text)
            };
            finalCategoryList.add(tempMap);
          }
          await FirebaseInteractions.updateCategories(
                  userDirectory, finalCategoryList)
              .then((value) => Navigator.popAndPushNamed(context, '/HomePage'));
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
              height: height! * 0.7,
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
