import 'package:flutter/material.dart';
import 'package:camelia/l10n/app_localizations.dart';

class ServiceTypeSelector extends StatelessWidget {
  final Function(String) onServiceTypeSelected;

  const ServiceTypeSelector({
    required this.onServiceTypeSelected,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
     
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.chooseYourServiceType,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.selectServiceTypeDescription,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              _buildServiceCard(
                context,
                icon: Icons.moped_rounded,
                title: l10n.deliveryService,
                subtitle: l10n.deliveryServiceDescription,
                color: const Color(0xFF4CAF50),
                serviceType: 'LIVRAISON',
              ),
              const SizedBox(height: 16),
              _buildServiceCard(
                context,
                icon: Icons.home_work_rounded,
                title: l10n.movingService,
                subtitle: l10n.movingServiceDescription,
                color: const Color(0xFF2196F3),
                serviceType: 'DÉMÉNAGEMENT ET TRANSPORT',
              ),
              const SizedBox(height: 16),
              _buildServiceCard(
                context,
                icon: Icons.inventory_2_rounded,
                title: l10n.shipmentService,
                subtitle: l10n.shipmentServiceDescription,
                color: const Color(0xFFFF9800),
                serviceType: 'EXPÉDITION',
              ),
              const SizedBox(height: 16),
              _buildServiceCard(
                context,
                icon: Icons.warehouse_rounded,
                title: l10n.storageService,
                subtitle: l10n.storageServiceDescription,
                color: const Color(0xFF9C27B0),
                serviceType: 'STOCKAGE ET LIVRAISON',
              ),
                const SizedBox(height: 16),
              _buildServiceCard(
                context,
                icon: Icons.flight_takeoff_rounded,
                title: l10n.internationalTransportService,
                subtitle: l10n.internationalTransportServiceDescription,
                color: const Color.fromARGB(255, 37, 95, 223),
                serviceType: 'TRANSPORT INTERNATIONAL',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String serviceType,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          onServiceTypeSelected(serviceType);
          // Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
