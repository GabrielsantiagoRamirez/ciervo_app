import '../../../core/errors/error_mapper.dart';
import '../../../core/network/api_response_unwrapper.dart';
import '../../../core/network/network_client.dart';
import '../../../core/result/result.dart';

class KycSubmission {
  const KycSubmission({
    required this.status,
    this.id,
    this.documentType,
    this.documentNumber,
    this.rejectionReason,
    this.submittedAt,
    this.reviewedAt,
  });

  final String? id;
  final String status;
  final String? documentType;
  final String? documentNumber;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
}

class KycRepository {
  const KycRepository(this._client);

  final NetworkClient _client;

  Future<Result<KycSubmission?>> me() => _guard(() async {
    final response = await _client.dio.get<dynamic>('/api/kyc/me');
    final data = unwrapApiMap(response.data);
    if (data.isEmpty) return null;
    return _fromJson(data);
  });

  Future<Result<void>> submit({
    required String documentType,
    required String documentNumber,
    String? notes,
  }) =>
      _guard(() async {
        await _client.dio.post<dynamic>(
          '/api/kyc/submit',
          data: {
            'documentType': documentType,
            'documentNumber': documentNumber,
            if (notes != null && notes.isNotEmpty) 'notes': notes,
          },
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

KycSubmission _fromJson(Map<String, dynamic> json) => KycSubmission(
  id: '${json['id'] ?? json['kycId'] ?? ''}',
  status: '${json['status'] ?? json['approvalStatus'] ?? 'Pending'}',
  documentType: _s(json['documentType']),
  documentNumber: _s(json['documentNumber'] ?? json['identityDocument']),
  rejectionReason: _s(json['rejectionReason'] ?? json['reason']),
  submittedAt: DateTime.tryParse('${json['submittedAt'] ?? json['createdAt'] ?? ''}'),
  reviewedAt: DateTime.tryParse('${json['reviewedAt'] ?? json['updatedAt'] ?? ''}'),
);

String? _s(dynamic value) =>
    value == null || value.toString().isEmpty ? null : value.toString();
