import 'package:flutter/material.dart';

import '../l10n/generated/app_localizations.dart';
import '../services/purchase_service.dart';

/// An explicit retry when the user regains connectivity without leaving the app.
class StoreRefreshButton extends StatelessWidget {
  const StoreRefreshButton({super.key});

  @override
  Widget build(BuildContext context) {
    final purchases = PurchaseScope.maybeOf(context);
    if (purchases == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: TextButton.icon(
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(purchases.isRefreshing ? l10n.shopLoading : l10n.shopRetry),
        onPressed: purchases.isRefreshing || purchases.isBusy
            ? null
            : () async {
                final messenger = ScaffoldMessenger.of(context);
                await purchases.refresh();
                if (!context.mounted) return;
                messenger
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        purchases.readiness == StoreReadiness.ready &&
                                purchases.hasPrices
                            ? l10n.shopRefreshed
                            : l10n.shopRetryFailed,
                      ),
                    ),
                  );
              },
      ),
    );
  }
}
