/// **Parrainage** — maquette « Compte — Client / 6 ».
///
/// Anciennement l'onglet « Portefeuille ». Décision produit du 13 septembre
/// 2026 : pas de portefeuille client, les paiements se font directement ; le
/// tableau ambassadeur (`GET /v1/me/ambassador-code/`, retrait compris) vit
/// désormais ici, dans le compte.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../shared/services/wallet_service.dart';
import '../../../shared/state/wallet_controller.dart';
import '../../../shared/widgets/flow_widgets.dart';
import '../../../shared/widgets/wallet_view.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late final WalletController _wallet;

  @override
  void initState() {
    super.initState();
    _wallet = WalletController(
      service: context.read<WalletService>(),
      kind: WalletKind.ambassador,
    );
  }

  @override
  void dispose() {
    _wallet.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ChangeNotifierProvider<WalletController>.value(
      value: _wallet,
      child: FlowScaffold(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: FlowHeader(title: l10n.accountReferral, large: true),
            ),
            const Expanded(child: WalletView()),
          ],
        ),
      ),
    );
  }
}
