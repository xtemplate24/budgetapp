import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseInteractions {
  static Future<void> updateIncome(documentReference, amount) {
    return documentReference
        .update({'income': amount})
        .then((value) => print('updated'))
        .catchError((error) => print("Failed to update user: $error"));
  }

  static Future<void> deleteCategories(documentReference) async {
    final collection =
        await documentReference.collection("category_and_budget").get();

    final batch = FirebaseFirestore.instance.batch();

    for (final doc in collection.docs) {
      batch.delete(doc.reference);
    }
    print('deleted');
    return batch.commit();
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

  static Future<void> submitTransaction(
    documentReference,
    Map<String, dynamic> transaction,
  ) async {
    documentReference.collection('transactions').add(transaction).then((_) {
      print("collection created");
    }).catchError((_) {
      print("an error occured");
    });
  }

  static Future<int?> getIncome(documentReference) async {
    await documentReference.get().then((val) {
      print(val.data()['income']);
      return val.data()['income'];
    }).catchError((_) {
      print("an error occured");
      return -1;
    });
  }
}
