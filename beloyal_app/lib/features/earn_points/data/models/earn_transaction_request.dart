/// Request body for the final earn-points transaction submission.
///
/// Endpoint: POST /business/{id}/transactions/earn
class EarnTransactionRequest {
  const EarnTransactionRequest({
    required this.billAmount,
    required this.guests,
    this.invoiceNumber,
    this.note,
  });

  /// Total bill amount.
  final double billAmount;

  /// Per-guest allocation of the bill amount.
  final List<GuestAllocation> guests;

  /// Optional invoice reference number.
  final String? invoiceNumber;

  /// Optional staff note.
  final String? note;

  Map<String, dynamic> toJson() => {
    'billAmount': billAmount,
    'guests': guests.map((g) => g.toJson()).toList(),
    if (invoiceNumber != null && invoiceNumber!.isNotEmpty)
      'invoiceNumber': invoiceNumber,
    if (note != null && note!.isNotEmpty) 'note': note,
  };
}

class GuestAllocation {
  const GuestAllocation({required this.customerId});

  final int customerId;

  Map<String, dynamic> toJson() => {'customerId': customerId};
}
