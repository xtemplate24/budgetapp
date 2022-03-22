import 'package:budgetapp/screens/home/home_view.dart';
import 'package:budgetapp/screens/login/login_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class HomePageState extends State<HomePage> {
  User? user = FirebaseAuth.instance.currentUser;
  double? height;
  double? width;
  QuerySnapshot<Map<String, dynamic>>? querySnapshot;

  @override
  void initState() {
    super.initState();
    height = 100.h;
    width = 100.w;

  }

  @override
  Widget build(BuildContext context) {
    CollectionReference users = FirebaseFirestore.instance.collection('users');

    

    if (querySnapshot! == null) {
      print("first login");
    } else {
      for (var doc in querySnapshot!.docs) {
        // Getting data directly
        print(doc.get('id'));
      }
    }

    print("in home page");

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
              ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (BuildContext context) => LoginPage(),
                        ),
                        (route) => false);
                  },
                  child: Text("Logout")),
              Text("HOME PAGE"),
              Text(user!.email.toString()),
              StreamBuilder(
                stream: users.snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (!snapshot.hasData) {
                    return const Text('Loading...');
                  } else {
                    return Expanded(
                      child: ListView(
                        children: snapshot.data!.docs.map((users) {
                          return Center(
                            child: ListTile(
                              title: Text(users['email']),
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
  }
}
