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

class SetCategoryPage extends StatefulWidget {
  static const routeName = '/SetCategoryPage';
  @override
  State<SetCategoryPage> createState() => SetCategoryPageState();
}

class SetCategoryPageState extends State<SetCategoryPage> {
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;
  List<String> categoryList = [];
  final categoryInputController = TextEditingController();
  List<TextEditingController> controllers = [];
  List<TextField> fields = [];
  List<Map<String, dynamic>> finalCategoryList = [];
  DocumentReference? userDocument;
  CollectionReference? userCategoryRef;
  List<Map> categories = [];
  bool dataRetrieved = false;

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;
    categoryList = [];
  }

  void addToList(String categoryname, bool fromPrevious, int index) {
    categoryname = categoryname.trim().toLowerCase();
    final controller = TextEditingController();
    if (fromPrevious) {
      controller.text = categories[index]['amount'].toString();
    }
    final field = TextField(
      keyboardType: TextInputType.number,
      controller: controller,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        labelText: "budget per month",
      ),
    );
    setState(() {
      if (categoryList.contains(categoryname)) {
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
        categoryList.add(categoryname);
        controllers.add(controller);
        fields.add(field);
      }
    });
  }

  Future<void> getCategories() async {
    // Get docs from collection reference

    userCategoryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection("category_and_budget");
    QuerySnapshot querySnapshot = await userCategoryRef!.get();
    categories = querySnapshot.docs.map((doc) => doc.data() as Map).toList();
    print('Categories: ${categories}');
    for (int i = 0; i < categories.length; i++) {
      addToList(categories[i]['name'], true, i);
    }
    print('Categories list: ${categoryList}');
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference userDirectory =
        FirebaseFirestore.instance.collection('users').doc(user!.uid);

    if (!dataRetrieved) {
      getCategories();
      print("HELLO");
      setState(() {
        dataRetrieved = true;
      });
    }

    print("in change categories page");

    Widget nextButton = ElevatedButton(
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
        for (int i = 0; i < categoryList.length; i++) {
          Map<String, dynamic> tempMap = {
            "name": categoryList[i],
            "amount":
                controllers[i].text.isEmpty ? 0 : int.parse(controllers[i].text)
          };
          finalCategoryList.add(tempMap);
        }
        await FirebaseInteractions.deleteCategories(userDirectory)
            .then((value) async {
          await FirebaseInteractions.updateCategories(
                  userDirectory, finalCategoryList)
              .then((value) => Navigator.popAndPushNamed(context, '/HomePage'));
        });
      },
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Set category page"),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Container(
                height: height! * 0.7,
                child: Column(
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
                          itemCount: categoryList.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Dismissible(
                              onDismissed: ((direction) {
                                setState(() {
                                  categoryList.removeAt(index);
                                  controllers.removeAt(index);
                                  fields.removeAt(index);
                                });
                              }),
                              key: Key(categoryList[index]),
                              background: Container(color: Colors.red),
                              direction: DismissDirection.endToStart,
                              child: Container(
                                height: 50,
                                child: Row(children: [
                                  Text(
                                    categoryList[index],
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
                              if (categoryInputController.text.isNotEmpty) {
                                addToList(
                                    categoryInputController.text, false, 0);
                                categoryInputController.clear();
                              }
                            },
                            child: Text("Add")),
                      ],
                    ),
                  ],
                )),
            nextButton,
          ],
        ),
      ),
    );
  }
}
