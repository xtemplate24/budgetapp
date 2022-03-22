import 'package:budgetapp/screens/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

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

    print("in setup page");

    return Scaffold(
                appBar: AppBar(
                  title: const Text("Setup page"),
                ),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
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
                      const Text("Test"),
                    ],
                  ),
                ),
            
   
        );
  }
}
