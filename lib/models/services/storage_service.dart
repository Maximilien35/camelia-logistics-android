import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadImage(File imageFile, String path) async {
    try {
      Reference ref = _storage.ref().child(path);

      UploadTask uploadTask = ref.putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception("Erreur Storage lors de l'upload : ${e.message}");
    }
  }
}
