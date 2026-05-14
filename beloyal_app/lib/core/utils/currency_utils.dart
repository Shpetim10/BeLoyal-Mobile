/// Canonical currency enum for the BeLoyal app.
///
/// Currency is set once at business registration and applies to all money
/// amounts in that business: catalog items, variants, coupons, earning rules,
/// transactions, and customer-facing displays.
enum BusinessCurrency {
  lek,
  euro,
  dollar;

  /// Parse from any backend code or display code (case-insensitive).
  static BusinessCurrency fromCode(String? code) =>
      switch ((code ?? '').trim().toUpperCase()) {
        'ALL' || 'LEK' => BusinessCurrency.lek,
        'EUR' || 'EURO' => BusinessCurrency.euro,
        'USD' || 'DOLLAR' => BusinessCurrency.dollar,
        _ => BusinessCurrency.lek,
      };

  /// ISO 4217 / backend storage code sent to and received from the API.
  String get code => switch (this) {
    BusinessCurrency.lek => 'ALL',
    BusinessCurrency.euro => 'EUR',
    BusinessCurrency.dollar => 'USD',
  };

  /// Short symbol shown in price displays.
  String get symbol => switch (this) {
    BusinessCurrency.lek => 'L',
    BusinessCurrency.euro => '€',
    BusinessCurrency.dollar => '\$',
  };

  /// Human-readable label for dropdowns and settings.
  String get displayName => switch (this) {
    BusinessCurrency.lek => 'Albanian Lek (ALL)',
    BusinessCurrency.euro => 'Euro (€)',
    BusinessCurrency.dollar => 'US Dollar (\$)',
  };

  /// Format a numeric amount using this currency's symbol.
  String format(double amount) {
    final formatted = amount.toStringAsFixed(2);
    return switch (this) {
      BusinessCurrency.lek => '$formatted L',
      BusinessCurrency.euro => '€$formatted',
      BusinessCurrency.dollar => '\$$formatted',
    };
  }
}

/// Returns the currency symbol for a raw currency code string.
/// Safe fallback to 'ALL' when the code is unknown.
String currencySymbol(String? code) =>
    BusinessCurrency.fromCode(code).symbol;

/// Formats [amount] with the symbol derived from [code].
String formatCurrency(double amount, String? code) =>
    BusinessCurrency.fromCode(code).format(amount);

/// Formats [amount] with a currency symbol (when symbol is provided directly from backend).
/// Handles both symbol strings (€, L, $) and currency codes (EUR, ALL, USD).
String formatCurrencyWithSymbol(double amount, String? currencySymbolOrCode) {
  if (currencySymbolOrCode == null || currencySymbolOrCode.isEmpty) {
    return '${amount.toStringAsFixed(2)} L';
  }

  final trimmed = currencySymbolOrCode.trim();
  final formatted = amount.toStringAsFixed(2);

  // If it's already a symbol (€, L, $), use it directly
  switch (trimmed) {
    case '€':
      return '€$formatted';
    case 'L':
      return '$formatted L';
    case '\$':
      return '\$$formatted';
    default:
      // Otherwise treat as currency code and convert
      return formatCurrency(amount, trimmed);
  }
}
