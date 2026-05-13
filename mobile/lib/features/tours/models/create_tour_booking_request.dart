class CreateTourBookingRequest {
  const CreateTourBookingRequest({
    required this.productId,
    required this.offerId,
    required this.scheduledFor,
    required this.adults,
    required this.children,
    this.idempotencyKey,
  });

  final String productId;
  final String offerId;
  final DateTime scheduledFor;
  final int adults;
  final int children;
  final String? idempotencyKey;

  Map<String, dynamic> toJson() {
    return {
      'productId': productId.trim(),
      'offerId': offerId.trim(),
      'scheduledFor': scheduledFor.toUtc().toIso8601String(),
      'adults': adults,
      'children': children,
      if ((idempotencyKey ?? '').trim().isNotEmpty)
        'idempotencyKey': idempotencyKey!.trim(),
    };
  }
}
