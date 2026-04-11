// ignore_for_file: unused_local_variable, use_build_context_synchronously

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
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
                  Navigator.of(context).pop(false), 
              child: const Text('ANNULER'),
            ),
            TextButton(
              onPressed: () {
                //context.go('/home_custom');
                Navigator.of(context).pop();
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
    required BuildContext context,
  }) async {
    final FirebaseFunctions functions = FirebaseFunctions.instanceFor(
      region: region,
    );

    final Map<String, String> roleToFunction = {
      'admin': 'setAdminRol',
      'deliverer': 'setDelivererRol',
      'collaborator': 'setCollabRol',
    };

    final String functionName = roleToFunction[role.toLowerCase()] ?? 'set${role}Rol';
    try {
      final HttpsCallable callable = functions.httpsCallable(functionName);

      final HttpsCallableResult result = await callable.call({
        'uid': targetUid,
      });
      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rôle $role attribué avec succès pour UID: $targetUid')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de l\'attribution du rôle: ${result.data['message'] ?? 'erreur inconnue'}')),
        );
        if (kDebugMode) {
          print('Échec de l\'attribution du rôle: ${result.data['message']}');
        }
      }
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur Cloud Functions: ${e.code}')),
      );
      if (kDebugMode) {
        print('Erreur d\'appel de la fonction: ${e.code} - ${e.message}');
      }
      rethrow;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'attribution du rôle: $e')),
      );
      if (kDebugMode) {
        print('Erreur générale: $e');
      }
      rethrow;
    }
  }

  Future<void> setDelivererRole({
    required String targetUid,
    required String region,
    required BuildContext context,
  }) async {
    return setRole(
      targetUid: targetUid,
      role: 'deliverer',
      region: region,
      context: context,
    );
  }
}
