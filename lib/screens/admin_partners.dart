import 'package:camelia/models/services/partner_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Gestion des entreprises partenaires B2B (API de commandes).
/// Réservé aux admins — appelle [PartnerService] (Cloud Functions `functions/partnerAdmin.js`).
class AdminPartnersScreen extends StatefulWidget {
  const AdminPartnersScreen({super.key});

  @override
  State<AdminPartnersScreen> createState() => _AdminPartnersScreenState();
}

class _AdminPartnersScreenState extends State<AdminPartnersScreen> {
  final PartnerService _partnerService = PartnerService();
  late Future<List<PartnerModel>> _partnersFuture;

  @override
  void initState() {
    super.initState();
    _partnersFuture = _partnerService.listPartners();
  }

  void _refresh() {
    setState(() {
      _partnersFuture = _partnerService.listPartners();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              bottom: 30,
              left: 24,
              right: 24,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    'Partenaires API',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                FloatingActionButton(
                  heroTag: 'add_partner',
                  onPressed: () => _showCreatePartnerDialog(context),
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add_rounded, color: Color(0xFF6C63FF)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<PartnerModel>>(
              future: _partnersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6C63FF),
                      strokeWidth: 2,
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      snapshot.error.toString(),
                      style: GoogleFonts.poppins(color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final partners = snapshot.data ?? [];
                if (partners.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Aucun partenaire pour le moment',
                          style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: partners.length,
                  itemBuilder: (context, index) {
                    return _PartnerCard(
                      partner: partners[index],
                      onRotateKey: () => _rotateKey(partners[index]),
                      onToggleStatus: () => _toggleStatus(partners[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _rotateKey(PartnerModel partner) async {
    final confirmed = await _confirm(
      title: 'Régénérer la clé API ?',
      message:
          "L'ancienne clé de ${partner.name} cessera immédiatement de fonctionner.",
    );
    if (confirmed != true) return;

    try {
      final apiKey = await _partnerService.rotateApiKey(partner.id);
      if (!mounted) return;
      _showApiKeyDialog(apiKey, partnerName: partner.name);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _toggleStatus(PartnerModel partner) async {
    final suspending = partner.isActive;
    final confirmed = await _confirm(
      title: suspending ? 'Suspendre ce partenaire ?' : 'Réactiver ce partenaire ?',
      message: suspending
          ? "${partner.name} ne pourra plus créer de commandes tant qu'il n'est pas réactivé."
          : "${partner.name} pourra de nouveau appeler l'API.",
    );
    if (confirmed != true) return;

    try {
      await _partnerService.setSuspended(partner.id, suspending);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<bool?> _confirm({required String title, required String message}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(message, style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.poppins()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Confirmer', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showCreatePartnerDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final webhookController = TextEditingController();
    bool inProgress = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.all(24),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nouveau partenaire',
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: nameController,
                          decoration: _fieldDecoration('Nom de l\'entreprise'),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          decoration: _fieldDecoration('Email de contact (optionnel)'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: webhookController,
                          decoration: _fieldDecoration('URL webhook (optionnel)'),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: inProgress
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setStateDialog(() => inProgress = true);
                                    try {
                                      final apiKey = await _partnerService.createPartner(
                                        name: nameController.text.trim(),
                                        contactEmail: emailController.text.trim().isEmpty
                                            ? null
                                            : emailController.text.trim(),
                                        webhookUrl: webhookController.text.trim().isEmpty
                                            ? null
                                            : webhookController.text.trim(),
                                      );
                                      if (!ctx.mounted) return;
                                      Navigator.pop(ctx);
                                      _showApiKeyDialog(apiKey, partnerName: nameController.text.trim());
                                      _refresh();
                                    } catch (e) {
                                      setStateDialog(() => inProgress = false);
                                      if (!ctx.mounted) return;
                                      ScaffoldMessenger.of(ctx).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  },
                            child: inProgress
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text('Créer', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  void _showApiKeyDialog(String apiKey, {required String partnerName}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.vpn_key_rounded, color: Colors.orange.shade700, size: 26),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Clé API de $partnerName',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Copiez cette clé maintenant : elle ne sera plus jamais affichée. '
                  'Transmettez-la de façon sécurisée à l\'équipe technique du partenaire.',
                  style: GoogleFonts.poppins(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: SelectableText(
                    apiKey,
                    style: GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: apiKey));
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Clé copiée dans le presse-papiers')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, color: Colors.white),
                    label: Text('Copier', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Fermer', style: GoogleFonts.poppins(color: Colors.grey.shade600)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PartnerCard extends StatelessWidget {
  final PartnerModel partner;
  final VoidCallback onRotateKey;
  final VoidCallback onToggleStatus;

  const _PartnerCard({
    required this.partner,
    required this.onRotateKey,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.06), blurRadius: 16),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF8B84FF)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.business_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    if (partner.contactEmail != null)
                      Text(
                        partner.contactEmail!,
                        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: partner.isActive
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  partner.isActive ? 'Actif' : 'Suspendu',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: partner.isActive ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(Icons.vpn_key_outlined, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '${partner.apiKeyPrefix}••••••••',
                style: GoogleFonts.robotoMono(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(width: 16),
              Icon(Icons.receipt_long_rounded, size: 16, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(
                '${partner.monthlyOrderCount} commandes',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onRotateKey,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF6C63FF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF6C63FF)),
                  label: Text(
                    'Régénérer la clé',
                    style: GoogleFonts.poppins(color: const Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onToggleStatus,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: partner.isActive ? Colors.red.shade300 : Colors.green.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(
                    partner.isActive ? Icons.block_rounded : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: partner.isActive ? Colors.red.shade400 : Colors.green.shade600,
                  ),
                  label: Text(
                    partner.isActive ? 'Suspendre' : 'Réactiver',
                    style: GoogleFonts.poppins(
                      color: partner.isActive ? Colors.red.shade400 : Colors.green.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
