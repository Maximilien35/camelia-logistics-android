import 'package:camelia/models/services/launch_url.dart';
import 'package:flutter/material.dart';
import 'package:camelia/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.help),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('📦 Clients'),
          _buildExpansionTile(l10n.colis, l10n.colisAns),
          _buildExpansionTile(l10n.modifyAddress, l10n.modifyAddressAns),
          _buildExpansionTile(l10n.setupAddress, l10n.setupAddressAns),

          const SizedBox(height: 20),
          _buildSectionHeader(l10n.faqGetDeliverers),

          _buildExpansionTile(l10n.faqClientAbsent, l10n.faqClientAbsentAns),

          const SizedBox(height: 20),
          _buildSectionHeader(l10n.faqTechSupportTitle),
          _buildExpansionTile(l10n.faqAppBug, l10n.faqAppBugAns),
          _buildExpansionTile(l10n.faqNoNotif, l10n.faqNoNotifAns),

          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => launchURL(
                        "https://wa.me/+237698209152?text=${Uri.encodeComponent("Bonjour, j'ai une question.")}",context
                      ),
            icon: const Icon(Icons.support_agent),
            label: Text(l10n.contactSupport),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }


  // Widget pour les titres de section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF6C63FF),
        ),
      ),
    );
  }

  // Widget pour chaque question/réponse
  Widget _buildExpansionTile(String question, String answer) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        iconColor: const Color(0xFF6C63FF),
        collapsedIconColor: Colors.grey.shade600,
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: Colors.grey.shade900,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.poppins(
                color: Colors.grey.shade600,
                height: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
