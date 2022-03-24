import 'dart:ffi';

import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseInteractions {
  static Future<void> updateIncome(documentReference, amount) {
    return documentReference
        .update({'income': amount})
        .then((value) => print('updated'))
        .catchError((error) => print("Failed to update user: $error"));
  }

  static Future<void> updateCategories(
      documentReference, List<Map<String, dynamic>> categorylist) async {
    for (int i = 0; i < categorylist.length; i++) {
      documentReference
          .collection("category_and_budget")
          .add(categorylist[i])
          .then((_) {
        print("collection created");
      }).catchError((_) {
        print("an error occured");
      });
    }
  }
}
