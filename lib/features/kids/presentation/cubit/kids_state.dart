import '../../domain/entities/child_profile.dart';

enum KidsStatus {
  initial,
  loading,
  loaded,
  empty,
  failure,
  actionLoading,
  saved,
}

class KidsState {
  const KidsState({
    this.status = KidsStatus.initial,
    this.children = const [],
    this.selectedChild,
    this.overview = const {},
    this.errorMessage,
    this.successMessage,
  });

  final KidsStatus status;
  final List<ChildProfile> children;
  final ChildProfile? selectedChild;
  final Map<String, dynamic> overview;
  final String? errorMessage;
  final String? successMessage;

  bool get isLoading =>
      status == KidsStatus.loading || status == KidsStatus.actionLoading;

  KidsState copyWith({
    KidsStatus? status,
    List<ChildProfile>? children,
    ChildProfile? selectedChild,
    Map<String, dynamic>? overview,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return KidsState(
      status: status ?? this.status,
      children: children ?? this.children,
      selectedChild: selectedChild ?? this.selectedChild,
      overview: overview ?? this.overview,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
    );
  }
}
