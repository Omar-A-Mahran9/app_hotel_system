import 'package:flutter/material.dart';

import '../errors/failure.dart';
import '../errors/failure_l10n.dart';
import '../localization/l10n.dart';
import '../presentation/ui_state.dart';
import 'loading_view.dart';
import 'message_view.dart';

/// Renders a [UiState] with the design-system loading / empty / error views,
/// delegating the success case to [onSuccess]. Keeps every screen's
/// state-handling consistent.
///
/// Pass [skeleton] to replace the centred spinner with a Figma-style skeleton
/// placeholder (see `lib/core/widgets/skeleton.dart`). When omitted the loading
/// state stays a [LoadingView] — screens opt in to skeletons as they are
/// migrated.
class UiStateView<T> extends StatelessWidget {
  const UiStateView({
    super.key,
    required this.state,
    required this.onSuccess,
    this.onRetry,
    this.emptyTitle,
    this.emptyMessage,
    this.skeleton,
  });

  final UiState<T> state;
  final Widget Function(T data) onSuccess;
  final VoidCallback? onRetry;
  final String? emptyTitle;
  final String? emptyMessage;
  final Widget? skeleton;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return state.map(
      initial: () => const SizedBox.shrink(),
      loading: () => skeleton ?? LoadingView(label: l10n.stateLoadingTitle),
      success: onSuccess,
      empty: () => EmptyView(
        title: emptyTitle ?? l10n.stateEmptyTitle,
        message: emptyMessage ?? l10n.stateEmptySubtitle,
      ),
      failure: (Failure failure) => ErrorView(
        title: l10n.stateErrorTitle,
        message: failure.localizedMessage(l10n),
        actionLabel: failure.isRetryable && onRetry != null
            ? l10n.actionRetry
            : null,
        onAction: failure.isRetryable ? onRetry : null,
      ),
    );
  }
}
