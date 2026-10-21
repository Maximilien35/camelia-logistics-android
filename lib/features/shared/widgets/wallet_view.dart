/// Vue d'un portefeuille, partagée par l'onglet Gains (chauffeur) et
/// Portefeuille / Parrainage (client).
///
/// Les deux portefeuilles réels ont la même forme — un solde, un historique, une
/// demande de retrait — mais pas les mêmes routes ; c'est [WalletController] qui
/// porte la différence, pas deux écrans jumeaux.
///
/// Le solde affiché est **celui du serveur**. Les seuils de retrait sont
/// appliqués côté serveur et remontent par leurs codes d'erreur, mappés en
/// messages localisés — l'app ne les duplique pas.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_error_messages.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../models/wallet.dart';
import '../state/wallet_controller.dart';
import 'money.dart';
import 'primary_button.dart';
import '../../../core/theme/app_icons.dart';
import 'skeleton.dart';

class WalletView extends StatefulWidget {
  const WalletView({super.key, this.title, this.header});

  /// Titre de section, différent pour le chauffeur et l'ambassadeur.
  final String? title;

  /// Bloc propre à un seul portefeuille, inséré au-dessus du solde.
  ///
  /// Sert au récapitulatif de gains du chauffeur
  /// (`GET /v1/driver/earnings/summary/`, § 7.4.4), qui n'a pas d'équivalent
  /// ambassadeur : une vue partagée, pas deux écrans jumeaux.
  final Widget? header;

  @override
  State<WalletView> createState() => _WalletViewState();
}

class _WalletViewState extends State<WalletView> {
  @override
  void initState() {
    super.initState();
    // Un seul chargement, à l'ouverture. Aucun sondage (règle n°5) : le
    // rafraîchissement est un geste de l'utilisateur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletController>().refresh();
    });
  }

  Future<void> _openWithdrawSheet() async {
    final controller = context.read<WalletController>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => ChangeNotifierProvider<WalletController>.value(
        value: controller,
        child: const _WithdrawSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<WalletController>();

    if (wallet.loading && !wallet.hasLoaded) {
      return ListView(
        padding: const EdgeInsets.all(AppDimens.screenPadding),
        children: const [SkeletonCardList(count: 4)],
      );
    }

    if (!wallet.hasLoaded && wallet.failure != null) {
      return _LoadError(
        message: messageForFailure(l10n, wallet.failure!),
        onRetry: wallet.refresh,
        retryLabel: l10n.commonRetry,
      );
    }

    return RefreshIndicator(
      onRefresh: wallet.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimens.screenPadding,
          20,
          AppDimens.screenPadding,
          24,
        ),
        children: [
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: const TextStyle(
                fontFamily: AppFonts.display,
                fontWeight: FontWeight.w700,
                fontSize: AppFontSize.headline,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          if (widget.header != null) ...[
            widget.header!,
            const SizedBox(height: AppSpacing.md),
          ],

          _BalanceCard(
            balance: wallet.balance,
            totalEarned: wallet.totalEarned,
            l10n: l10n,
          ),

          if (wallet.kind == WalletKind.ambassador) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: l10n.ambassadorUsageCount,
                    value: '${wallet.usageCount}',
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatTile(
                    label: l10n.ambassadorConversionCount,
                    value: '${wallet.conversionCount}',
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: l10n.walletWithdrawAction,
            busy: wallet.busy,
            onPressed: wallet.hasLoaded ? _openWithdrawSheet : null,
          ),

          if (wallet.lastWithdrawal != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _PendingNotice(message: l10n.walletWithdrawPending),
          ],
          if (wallet.failure != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorNotice(message: messageForFailure(l10n, wallet.failure!)),
          ],

          const SizedBox(height: AppSpacing.xxxl),
          Text(
            wallet.kind == WalletKind.ambassador
                ? l10n.ambassadorRecentTitle
                : l10n.walletHistoryTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.bodyLarge,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (wallet.entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                l10n.walletHistoryEmpty,
                style: const TextStyle(
                  fontSize: AppFontSize.label,
                  color: AppColors.inkMuted,
                ),
              ),
            )
          else
            for (final entry in wallet.entries)
              _LedgerRow(entry: entry, l10n: l10n),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.totalEarned,
    required this.l10n,
  });

  final String? balance;
  final String? totalEarned;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadii.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.walletBalanceLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: AppFontSize.micro,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: Color(0x99FFFFFF),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Le solde défile jusqu'à la valeur du serveur ; la dernière image
          // affiche exactement `formatAmount(balance)`.
          AnimatedAmount(
            balance,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: AppFontSize.hero,
              color: AppColors.white,
            ),
          ),
          if (totalEarned != null) ...[
            const SizedBox(height: AppSpacing.lg),
            Container(height: 1, color: const Color(0x22FFFFFF)),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.walletTotalEarnedLabel,
                  style: const TextStyle(
                    fontSize: AppFontSize.label,
                    color: Color(0xCCFFFFFF),
                  ),
                ),
                Text(
                  formatAmount(totalEarned),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppFontSize.body,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppColors.white,
      borderRadius: BorderRadius.circular(AppRadii.field),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontFamily: AppFonts.display,
            fontWeight: FontWeight.w700,
            fontSize: AppFontSize.title,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.entry, required this.l10n});

  final LedgerEntry entry;
  final AppLocalizations l10n;

  /// Libellé localisé d'un type d'écriture.
  ///
  /// Un type inconnu retombe sur sa valeur brute plutôt que sur un message
  /// générique : le backend peut en ajouter un, et la ligne doit rester lisible.
  String get _label => switch (entry.type) {
    LedgerEntryType.paymentIn => l10n.ledgerPaymentIn,
    LedgerEntryType.commission => l10n.ledgerCommission,
    LedgerEntryType.driverCredit => l10n.ledgerDriverCredit,
    LedgerEntryType.withdrawal => l10n.ledgerWithdrawal,
    LedgerEntryType.refund => l10n.ledgerRefund,
    LedgerEntryType.bonusReferral => l10n.ledgerBonusReferral,
    LedgerEntryType.ambassadorCommission => l10n.ledgerAmbassadorCommission,
    null => entry.rawType,
  };

  @override
  Widget build(BuildContext context) {
    final date = entry.createdAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: entry.isDebit ? AppColors.surface : AppColors.brandTint,
              borderRadius: BorderRadius.circular(AppRadii.small),
            ),
            child: Icon(
              entry.isDebit ? AppIcons.arrowUp : AppIcons.arrowDown,
              size: 17,
              color: entry.isDebit ? AppColors.inkMuted : AppColors.success,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: AppFontSize.body,
                    color: AppColors.ink,
                  ),
                ),
                if (entry.externalReference != null || date != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    [
                      if (date != null)
                        '${date.day.toString().padLeft(2, '0')}/'
                            '${date.month.toString().padLeft(2, '0')}/'
                            '${date.year}',
                      if (entry.externalReference != null)
                        entry.externalReference!,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            formatAmount(entry.amount, withSign: true),
            style: TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.body,
              color: entry.isDebit ? AppColors.ink : AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

/// Feuille de demande de retrait.
class _WithdrawSheet extends StatefulWidget {
  const _WithdrawSheet();

  @override
  State<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends State<_WithdrawSheet> {
  final _amount = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final raw = _amount.text.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (raw.isEmpty || double.tryParse(raw) == null) {
      setState(() => _error = l10n.walletWithdrawAmountRequired);
      return;
    }
    setState(() => _error = null);

    // Le montant part **en chaîne**, comme le `DecimalField` attendu. Les
    // seuils (minimum, plafond au solde) sont la décision du serveur.
    final ok = await context.read<WalletController>().requestWithdrawal(
      double.parse(raw).toStringAsFixed(2),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallet = context.watch<WalletController>();

    return Padding(
      padding: EdgeInsets.only(
        left: AppDimens.screenPadding,
        right: AppDimens.screenPadding,
        top: 22,
        // Laisse la place au clavier.
        bottom: MediaQuery.viewInsetsOf(context).bottom + 22,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.walletWithdrawTitle,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.title,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${l10n.walletBalanceLabel} · ${formatAmount(wallet.balance)}',
            style: const TextStyle(
              fontSize: AppFontSize.label,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          Text(
            l10n.walletWithdrawAmountLabel,
            style: const TextStyle(
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
            ],
            enabled: !wallet.busy,
            autofocus: true,
            style: const TextStyle(
              fontFamily: AppFonts.display,
              fontWeight: FontWeight.w700,
              fontSize: AppFontSize.title,
              color: AppColors.ink,
            ),
            decoration: InputDecoration(hintText: l10n.walletWithdrawHint),
            onSubmitted: (_) => _submit(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: AppFontSize.caption,
              ),
            ),
          ],
          // § 6.10ter révisé le 21 octobre 2026 : KPay prélève sa commission
          // sur le montant décaissé. Le taux est celui de KPay « en direct » :
          // l'app le signale sans jamais le chiffrer (règle n°3).
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.walletWithdrawFeeNotice,
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              height: 1.45,
              color: AppColors.inkMuted,
            ),
          ),
          if (wallet.failure != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _ErrorNotice(message: messageForFailure(l10n, wallet.failure!)),
          ],

          const SizedBox(height: AppSpacing.xxl),
          PrimaryButton(
            label: l10n.walletWithdrawConfirm,
            busy: wallet.busy,
            onPressed: _submit,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: wallet.busy ? null : () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
        ],
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x1A1FA463),
      borderRadius: BorderRadius.circular(AppRadii.small),
    ),
    child: Row(
      children: [
        const Icon(AppIcons.clock, size: 17, color: AppColors.success),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: AppFontSize.label,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ErrorNotice extends StatelessWidget {
  const _ErrorNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0x1AE5483A),
      borderRadius: BorderRadius.circular(AppRadii.small),
    ),
    child: Text(
      message,
      style: const TextStyle(
        color: AppColors.error,
        fontWeight: FontWeight.w600,
        fontSize: AppFontSize.label,
        height: 1.4,
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final Future<void> Function() onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppDimens.screenPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(AppIcons.error, size: 36, color: AppColors.borderStrong),
          const SizedBox(height: AppSpacing.lg),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: AppFontSize.body,
              height: 1.5,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    ),
  );
}
