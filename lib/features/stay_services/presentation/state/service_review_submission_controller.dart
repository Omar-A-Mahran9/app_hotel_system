import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/service_review_draft.dart';
import '../../domain/entities/submit_service_review.dart';
import 'service_review_providers.dart';
import 'stay_services_providers.dart' show ServiceOrderKey;

/// The state of the one-shot "submit service review" action. Mirrors
/// `ReviewSubmissionController`.
sealed class ServiceReviewActionState {
  const ServiceReviewActionState();

  bool get isSubmitting => this is ServiceReviewSubmitting;

  SubmitServiceReviewRequest? get requestOrNull => switch (this) {
        ServiceReviewSubmitting(:final SubmitServiceReviewRequest request) => request,
        ServiceReviewSubmitDone(:final SubmitServiceReviewRequest request) => request,
        ServiceReviewSubmitFailed(:final SubmitServiceReviewRequest request) => request,
        _ => null,
      };

  SubmitServiceReviewResult? get resultOrNull => this is ServiceReviewSubmitDone
      ? (this as ServiceReviewSubmitDone).result
      : null;

  Failure? get failureOrNull => this is ServiceReviewSubmitFailed
      ? (this as ServiceReviewSubmitFailed).failure
      : null;
}

class ServiceReviewIdle extends ServiceReviewActionState {
  const ServiceReviewIdle();
}

class ServiceReviewSubmitting extends ServiceReviewActionState {
  const ServiceReviewSubmitting(this.request);
  final SubmitServiceReviewRequest request;
}

class ServiceReviewSubmitDone extends ServiceReviewActionState {
  const ServiceReviewSubmitDone(this.request, this.result);
  final SubmitServiceReviewRequest request;
  final SubmitServiceReviewResult result;
}

class ServiceReviewSubmitFailed extends ServiceReviewActionState {
  const ServiceReviewSubmitFailed(this.request, this.failure);
  final SubmitServiceReviewRequest request;
  final Failure failure;
}

/// Owns the submit-service-review action. Mirrors `ReviewSubmissionController`.
class ServiceReviewSubmissionController extends Notifier<ServiceReviewActionState> {
  @override
  ServiceReviewActionState build() => const ServiceReviewIdle();

  Future<void> submit(ServiceOrderKey key, ServiceReviewDraft draft) async {
    final SubmitServiceReviewRequest request = SubmitServiceReviewRequest(
      reservationId: key.reservationId,
      serviceOrderId: key.orderId,
      rating: draft.rating,
      text: draft.normalizedText,
    );
    final ServiceReviewActionState current = state;
    if (current is ServiceReviewSubmitting && current.request == request) return;
    if (current is ServiceReviewSubmitDone &&
        current.request == request &&
        current.result.outcome.isSuccess) {
      return;
    }

    state = ServiceReviewSubmitting(request);
    try {
      final ServiceReviewContext ctx =
          await ref.read(serviceReviewContextProvider(key).future);
      final SubmitServiceReviewResult result =
          await ref.read(serviceReviewRepositoryProvider).submit(request, ctx);
      if (_superseded(request)) return;
      state = ServiceReviewSubmitDone(request, result);
      if (result.outcome.isSuccess) {
        ref.invalidate(serviceOrderReviewProvider(key));
      }
    } catch (error) {
      if (_superseded(request)) return;
      state = ServiceReviewSubmitFailed(request, ErrorMapper.toFailure(error));
    }
  }

  bool _superseded(SubmitServiceReviewRequest request) {
    final ServiceReviewActionState now = state;
    return now is ServiceReviewSubmitting && now.request != request;
  }

  void reset() => state = const ServiceReviewIdle();
}

final serviceReviewSubmissionControllerProvider =
    NotifierProvider<ServiceReviewSubmissionController, ServiceReviewActionState>(
  ServiceReviewSubmissionController.new,
);
