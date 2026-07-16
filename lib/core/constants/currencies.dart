/// Supported currencies. Kept in sync with the backend's
/// `fx_service.SUPPORTED_CURRENCIES` (the API also exposes them at
/// `GET /db/fx/currencies`).
class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency(this.code, this.symbol, this.name);
}

class Currencies {
  Currencies._();

  static const String defaultCode = 'INR';

  static const List<Currency> all = [
    Currency('INR', '₹', 'Indian Rupee'),
    Currency('USD', '\$', 'US Dollar'),
    Currency('EUR', '€', 'Euro'),
    Currency('GBP', '£', 'British Pound'),
    Currency('JPY', '¥', 'Japanese Yen'),
    Currency('CNY', '¥', 'Chinese Yuan'),
    Currency('AED', 'د.إ', 'UAE Dirham'),
    Currency('SGD', 'S\$', 'Singapore Dollar'),
    Currency('AUD', 'A\$', 'Australian Dollar'),
    Currency('CAD', 'C\$', 'Canadian Dollar'),
    Currency('CHF', 'Fr', 'Swiss Franc'),
    Currency('THB', '฿', 'Thai Baht'),
    Currency('MYR', 'RM', 'Malaysian Ringgit'),
    Currency('LKR', 'Rs', 'Sri Lankan Rupee'),
    Currency('NPR', 'Rs', 'Nepalese Rupee'),
    Currency('BDT', '৳', 'Bangladeshi Taka'),
    Currency('IDR', 'Rp', 'Indonesian Rupiah'),
    Currency('VND', '₫', 'Vietnamese Dong'),
    Currency('KRW', '₩', 'South Korean Won'),
    Currency('SAR', '﷼', 'Saudi Riyal'),
    Currency('QAR', '﷼', 'Qatari Riyal'),
    Currency('KWD', 'د.ك', 'Kuwaiti Dinar'),
    Currency('NZD', 'NZ\$', 'New Zealand Dollar'),
    Currency('ZAR', 'R', 'South African Rand'),
    Currency('HKD', 'HK\$', 'Hong Kong Dollar'),
    Currency('TWD', 'NT\$', 'New Taiwan Dollar'),
    Currency('PHP', '₱', 'Philippine Peso'),
    Currency('EGP', 'E£', 'Egyptian Pound'),
    Currency('TRY', '₺', 'Turkish Lira'),
    Currency('BRL', 'R\$', 'Brazilian Real'),
    Currency('MXN', 'Mex\$', 'Mexican Peso'),
  ];

  static Currency byCode(String? code) {
    final normalized = (code ?? '').trim().toUpperCase();
    return all.firstWhere(
      (c) => c.code == normalized,
      orElse: () => all.first,
    );
  }

  static String symbolFor(String? code) => byCode(code).symbol;
}
