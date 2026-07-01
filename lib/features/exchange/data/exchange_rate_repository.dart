import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';

class ExchangeRateItem {
  const ExchangeRateItem({
    required this.targetCurrency,
    required this.exchangeRate,
    this.source,
    this.retrievedAt,
  });

  factory ExchangeRateItem.fromJson(Map<String, dynamic> json) =>
      ExchangeRateItem(
        targetCurrency: '${json['targetCurrency'] ?? ''}',
        exchangeRate: _num(json['exchangeRate']) ?? 0,
        source: json['source']?.toString(),
        retrievedAt: DateTime.tryParse('${json['retrievedAt'] ?? ''}'),
      );

  final String targetCurrency;
  final double exchangeRate;
  final String? source;
  final DateTime? retrievedAt;
}

class ExchangeRateSnapshot {
  const ExchangeRateSnapshot({
    required this.baseCurrency,
    required this.rates,
    this.cacheMinutes,
  });

  factory ExchangeRateSnapshot.fromJson(Map<String, dynamic> json) {
    final ratesRaw = json['rates'];
    final rates = ratesRaw is List
        ? ratesRaw
            .whereType<Map>()
            .map((e) => ExchangeRateItem.fromJson(Map<String, dynamic>.from(e)))
            .where((r) => r.targetCurrency.isNotEmpty)
            .toList()
        : <ExchangeRateItem>[];
    return ExchangeRateSnapshot(
      baseCurrency: '${json['baseCurrency'] ?? 'USD'}',
      cacheMinutes: _int(json['cacheMinutes']),
      rates: rates,
    );
  }

  final String baseCurrency;
  final List<ExchangeRateItem> rates;
  final int? cacheMinutes;
}

class CurrencyCatalogItem {
  const CurrencyCatalogItem({
    required this.countryCode,
    required this.currency,
    this.exchangeRateFromUsd,
  });

  factory CurrencyCatalogItem.fromJson(Map<String, dynamic> json) =>
      CurrencyCatalogItem(
        countryCode: '${json['countryCode'] ?? ''}',
        currency: '${json['currency'] ?? ''}',
        exchangeRateFromUsd: _num(json['exchangeRateFromUsd']),
      );

  final String countryCode;
  final String currency;
  final double? exchangeRateFromUsd;
}

class CurrencyCatalog {
  const CurrencyCatalog({
    required this.baseCurrency,
    required this.currencies,
    this.cacheMinutes,
  });

  final String baseCurrency;
  final List<CurrencyCatalogItem> currencies;
  final int? cacheMinutes;

  List<String> get currencyCodes => currencies
      .map((c) => c.currency)
      .where((c) => c.isNotEmpty)
      .toSet()
      .toList();
}

class CurrencyConversion {
  const CurrencyConversion({
    required this.amount,
    required this.fromCurrency,
    required this.toCurrency,
    required this.convertedAmount,
    required this.exchangeRate,
    this.baseCurrency = 'USD',
  });

  factory CurrencyConversion.fromJson(Map<String, dynamic> json) =>
      CurrencyConversion(
        amount: _num(json['amount']) ?? 0,
        fromCurrency: '${json['fromCurrency'] ?? ''}',
        toCurrency: '${json['toCurrency'] ?? ''}',
        convertedAmount: _num(json['convertedAmount']) ?? 0,
        exchangeRate: _num(json['exchangeRate']) ?? 0,
        baseCurrency: '${json['baseCurrency'] ?? 'USD'}',
      );

  final double amount;
  final String fromCurrency;
  final String toCurrency;
  final double convertedAmount;
  final double exchangeRate;
  final String baseCurrency;
}

class ExchangeRateRepository {
  const ExchangeRateRepository(this._client);

  final NetworkClient _client;

  Future<Result<ExchangeRateSnapshot>> getRates() => _guard(() async {
        final response = await _client.dio.get<dynamic>('/api/exchange-rates');
        return ExchangeRateSnapshot.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<CurrencyConversion>> convert({
    required double amount,
    required String from,
    required String to,
  }) =>
      _guard(() async {
        final response = await _client.dio.get<dynamic>(
          '/api/exchange-rates/convert',
          queryParameters: {
            'amount': amount,
            'from': from,
            'to': to,
          },
        );
        return CurrencyConversion.fromJson(unwrapApiMap(response.data));
      });

  Future<Result<CurrencyCatalog>> getCurrencies() => _guard(() async {
        final response =
            await _client.dio.get<dynamic>('/api/catalogs/currencies');
        final map = unwrapApiMap(response.data);
        final currenciesRaw = map['currencies'];
        final items = currenciesRaw is List
            ? currenciesRaw
                .whereType<Map>()
                .map(
                  (e) => CurrencyCatalogItem.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .where((c) => c.currency.isNotEmpty)
                .toList()
            : <CurrencyCatalogItem>[];
        return CurrencyCatalog(
          baseCurrency: '${map['baseCurrency'] ?? 'USD'}',
          cacheMinutes: _int(map['cacheMinutes']),
          currencies: items,
        );
      });

  Future<Result<T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }
}

double? _num(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('$value');

int? _int(dynamic value) => value is int ? value : int.tryParse('$value');
