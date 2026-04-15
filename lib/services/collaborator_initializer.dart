import 'package:flutter/material.dart';
import '../models/services/cache_manager.dart';

/// Global initialization helper for collaborator features
class CollaboratorAppInitializer {
  /// Initialize all collaborator-related services
  /// Call this in main() after Firebase initialization
  static Future<void> initializeCollaboratorServices() async {
    // Initialize cache manager
    final cacheManager = CacheManager();
    await cacheManager.initialize();
  }

  /// Optional: Pre-warm cache with test data
  /// Useful for development/testing
  static void prewarmCacheDev(String collaboratorId, List<Map<String, dynamic>> sampleOrders) {
    final cacheManager = CacheManager();
    cacheManager.cacheCollaboratorOrders(collaboratorId, sampleOrders);
  }
}

/// Widget wrapper to handle collaborator initialization
class CollaboratorInitializerWidget extends StatelessWidget {
  final Widget child;
  
  const CollaboratorInitializerWidget({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: CollaboratorAppInitializer.initializeCollaboratorServices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }
        
        if (snapshot.hasError) {
          return _buildErrorScreen(snapshot.error);
        }
        
        return child;
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.blue.shade600,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Initialisation...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(dynamic error) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 48,
              ),
              const SizedBox(height: 16),
              const Text(
                'Erreur d\'initialisation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Détail: $error',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Retry
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
