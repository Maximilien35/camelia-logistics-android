import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AdminService {
  Future<void> handlePopInvoked(bool didPop, BuildContext context) async {
    if (didPop) {
      return;
    }
    bool? exitConfirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmer le Retour '),
          content: const Text(
            'Êtes-vous sûr de vouloir retouner a l\'accueil ?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(false), // Annuler l'action
              child: const Text('ANNULER'),
            ),
            TextButton(
              onPressed: () {
                context.go('/home_custom');
                // // 3. Fermer la boîte de dialogue
                Navigator.of(context).pop(true);
                // SystemNavigator.pop();
              },
              child: const Text('QUITTER'),
            ),
          ],
        );
      },
    );
  }

  Future<void> setRole({
    required String targetUid,
    required String role,
    required String region,
  }) async {
    final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
      region: region,
    );
    final String functionName = 'set${role}Rol';
    try {
      // Le nom de la fonction Cloud : 'setAdminRole' ou 'setDelivererRole'
      final HttpsCallable callable = functions.httpsCallable(functionName);

      // Appel avec l'UID en paramètre
      final HttpsCallableResult result = await callable.call({
        'uid': targetUid,
      });

      // Le résultat est retourné par votre Cloud Function (index.js)
      if (result.data['success'] == true) {
        SnackBar(
          content: Text('Rôle $role attribué avec succès pour UID: $targetUid'),
        );
      } else {
        if (kDebugMode) {
          print('Échec de l\'attribution du rôle: ${result.data['message']}');
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (kDebugMode) {
        print('Erreur d\'appel de la fonction: ${e.code} - ${e.message}');
      }
      rethrow; // Lance l'exception pour la gestion dans l'UI
    } catch (e) {
      if (kDebugMode) {
        print('Erreur générale: $e');
      }
      rethrow;
    }
  }
}
