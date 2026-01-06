import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Envoie un fichier et retourne son URL de téléchargement (String)
  Future<String> uploadImage(File imageFile, String path) async {
    try {
      // 1. Définir la référence de stockage
      Reference ref = _storage.ref().child(path);

      // 2. Tâche d'upload
      UploadTask uploadTask = ref.putFile(imageFile);

      // 3. Attendre la fin de l'upload
      TaskSnapshot snapshot = await uploadTask;

      // 4. Récupérer l'URL publique
      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      throw Exception("Erreur Storage lors de l'upload : ${e.message}");
    }
  }
}
