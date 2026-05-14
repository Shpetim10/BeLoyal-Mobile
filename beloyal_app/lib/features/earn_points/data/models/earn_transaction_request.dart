/// Request body for the final earn-points transaction submission.
///
/// Endpoint: POST /business/{id}/transactions/earn
class EarnTransactionRequest {
  const EarnTransactionRequest({
    required this.billAmount,
    required this.guests,
    this.invoiceNumber,
    this.note,
    this.couponQrCode,
  });

  final double billAmount;
  final List<GuestAllocation> guests;
  final String? invoiceNumber;
  final String? note;

  /// QR code of a REDEEMED discount coupon to apply. The backend will
  /// calculate points from the discounted amount and mark the coupon USED.
  final String? couponQrCode;

  Map<String, dynamic> toJson() => {
    'billAmount': billAmount,
    'guests': guests.map((g) => g.toJson()).toList(),
    if (invoiceNumber != null && invoiceNumber!.isNotEmpty)
      'invoiceNumber': invoiceNumber,
    if (note != null && note!.isNotEmpty) 'note': note,
    if (couponQrCode != null && couponQrCode!.isNotEmpty)
      'couponQrCode': couponQrCode,
  };
}

class GuestAllocation {
  const GuestAllocation({required this.customerId});

  final int customerId;

  Map<String, dynamic> toJson() => {'customerId': customerId};
}
