import 'package:budgetapp/components/color_theme.dart';
import 'package:budgetapp/components/standard_alert.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:budgetapp/screens/setup/setup.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;
  List<Object?> categories = [];
  List<Object?> transactions = [];
  CollectionReference? userCategoryRef;
  CollectionReference? userTransactionsRef;

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;
  }

  Future<void> getCategoriesAndTransactions() async {
    // Get docs from collection reference
    userCategoryRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection("category_and_budget");
    userTransactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection("transactions");

    QuerySnapshot querySnapshot = await userCategoryRef!.get();
    categories = querySnapshot.docs.map((doc) => doc.data()).toList();

    querySnapshot = await userTransactionsRef!.get();
    transactions = querySnapshot.docs.map((doc) => doc.data()).toList();

    print('Categories: ${categories}');
    print('Transactions: ${transactions}');
  }

  @override
  Widget build(BuildContext context) {
    getCategoriesAndTransactions();
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    print("in home page");

    return FutureBuilder<DocumentSnapshot>(
        future: users.doc(user!.uid).get(),
        builder:
            (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
                appBar: AppBar(
                  title: const Text("Home page"),
                ),
                body: const Center(child: Text("Oops, something went wrong")));
          } else if (snapshot.hasData && !snapshot.data!.exists) {
            users.doc(user!.uid) // <-- Document ID
                .set({
              'email': user!.email,
              'income': 0,
              'id': user!.uid
            }) // <-- Your data
                .then((_) {
              users.doc((user!.uid));
              print('Added');
              return SetupPage();
            }).catchError((error) {
              print('Add failed: $error');
              return HomePage();
            });
            return SetupPage();
          } else if (snapshot.connectionState == ConnectionState.done) {
            Map<String, dynamic> data =
                snapshot.data!.data() as Map<String, dynamic>;
            return WillPopScope(
              onWillPop: () async {
                return false;
              },
              child: Scaffold(
                appBar: AppBar(
                  title: const Text("Home page"),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                              onPressed: () async {
                                await FirebaseAuth.instance.signOut();
                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          LoginPage(),
                                    ),
                                    (route) => false);
                              },
                              child: Text("Logout")),
                          TextButton(
                              onPressed: () async {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialogOneOption(
                                          title: "test",
                                          content: "test",
                                          buttonText: "test",
                                          context: context);
                                    });
                              },
                              child: Text("Add transaction")),
                        ],
                      ),
                      Text(user!.email.toString()),
                      StreamBuilder(
                        stream: userTransactionsRef?.snapshots(),
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (!snapshot.hasData) {
                            return const Text('Loading...');
                          } else {
                            return Expanded(
                              child: ListView(
                                children:
                                    snapshot.data!.docs.map((transactions) {
                                  return Center(
                                    child: ListTile(
                                      title: Text(transactions['item']),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Scaffold(
              body: Center(
                child: SpinKitPianoWave(color: ColorTheme().gradientPurple),
              ),
            );
          }
        });
  }
}
