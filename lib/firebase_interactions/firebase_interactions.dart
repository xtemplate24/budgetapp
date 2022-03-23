

class FirebaseInteractions{
  static Future<void> updateIncome(collection, uid, amount) {
  return collection
    .doc(uid)
    .update({'income': amount})
    .then((value) => print('updated'))
    .catchError((error) => print("Failed to update user: $error"));
}

}