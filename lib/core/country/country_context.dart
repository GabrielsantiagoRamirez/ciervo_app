class CountryContext {
  const CountryContext({
    required this.countryCode,
    required this.city,
  });

  static const colombia = CountryContext(countryCode: 'CO', city: 'Bogota');
  static const chile = CountryContext(countryCode: 'CL', city: 'Santiago');

  final String countryCode;
  final String city;
}
