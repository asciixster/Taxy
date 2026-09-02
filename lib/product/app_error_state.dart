import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'app_failure.dart';

final class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.failure,
    this.onRetry,
    this.correlationId,
  });

  final AppFailure failure;
  final VoidCallback? onRetry;
  final String? correlationId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = switch (failure.kind) {
      AppFailureKind.networkOffline => l10n.offlineUnavailable,
      AppFailureKind.timeout => l10n.networkErrorMessage,
      AppFailureKind.authenticationRequired => l10n.authErrorMessage,
      AppFailureKind.authorizationDenied => l10n.authorizationErrorMessage,
      AppFailureKind.sessionExpired => l10n.sessionExpiredMessage,
      AppFailureKind.serviceUnavailable => l10n.serviceErrorMessage,
      AppFailureKind.serverError => l10n.serviceErrorMessage,
      AppFailureKind.malformedData => l10n.parsingErrorMessage,
      AppFailureKind.missingRequiredData => l10n.missingInformationImprove,
      AppFailureKind.localDataError => l10n.localDataUnavailable,
      AppFailureKind.unknown => l10n.genericErrorMessage,
    };
    return Semantics(
      liveRegion: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 42,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: onRetry,
                    child: Text(l10n.tryAgain),
                  ),
                ],
                if (correlationId != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    correlationId!,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
