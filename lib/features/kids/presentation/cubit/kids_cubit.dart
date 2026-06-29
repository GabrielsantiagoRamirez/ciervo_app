import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/user_error_message.dart';
import '../../domain/repositories/kids_repository.dart';
import 'kids_state.dart';

class KidsCubit extends Cubit<KidsState> {
  KidsCubit(this._repository) : super(const KidsState());

  final KidsRepository _repository;

  Future<void> loadChildren() async {
    emit(state.copyWith(status: KidsStatus.loading, clearMessages: true));
    final result = await _repository.children();
    result.when(
      success: (children) => emit(
        state.copyWith(
          status: children.isEmpty ? KidsStatus.empty : KidsStatus.loaded,
          children: children,
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: KidsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> loadChild(String childId) async {
    emit(state.copyWith(status: KidsStatus.loading, clearMessages: true));
    final child = await _repository.child(childId);
    final overview = await _repository.childOverview(childId);
    child.when(
      success: (profile) => overview.when(
        success: (data) => emit(
          state.copyWith(
            status: KidsStatus.loaded,
            selectedChild: profile,
            overview: data,
          ),
        ),
        failure: (error) => emit(
          state.copyWith(
            status: KidsStatus.failure,
            selectedChild: profile,
            errorMessage: UserErrorMessage.from(error),
          ),
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: KidsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> saveChild({
    String? childId,
    required Map<String, dynamic> data,
  }) async {
    emit(state.copyWith(status: KidsStatus.actionLoading, clearMessages: true));
    final result = childId == null
        ? await _repository.createChild(data)
        : await _repository.updateChild(childId, data);
    result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: KidsStatus.saved,
            successMessage: childId == null
                ? 'Menor creado.'
                : 'Menor actualizado.',
          ),
        );
      },
      failure: (error) => emit(
        state.copyWith(
          status: KidsStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> deleteChild(String childId) async {
    emit(state.copyWith(status: KidsStatus.actionLoading, clearMessages: true));
    final result = await _repository.deleteChild(childId);
    result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: KidsStatus.loaded,
            successMessage: 'Menor eliminado.',
          ),
        );
        loadChildren();
      },
      failure: (error) => emit(
        state.copyWith(
          status: KidsStatus.loaded,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<bool> saveAllowedBusinesses(
    String childId,
    List<String> businessIds,
  ) async {
    emit(state.copyWith(status: KidsStatus.actionLoading, clearMessages: true));
    final result = await _repository.saveAllowedBusinesses(
      childId,
      businessIds,
    );
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: KidsStatus.loaded,
            successMessage: 'Comercios permitidos actualizados.',
          ),
        );
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            status: KidsStatus.loaded,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }

  Future<void> loadBusinessCandidates(
    String childId, {
    String? query,
    String? city,
    int? categoryId,
  }) async {
    emit(state.copyWith(status: KidsStatus.loading, clearMessages: true));
    final result = await _repository.businessCandidates(
      childId,
      query: query,
      city: city,
      categoryId: categoryId,
    );
    result.when(
      success: (items) => emit(
        state.copyWith(
          status: KidsStatus.loaded,
          overview: {...state.overview, 'allowedBusinesses': items},
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: KidsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<void> loadAllowedCategories(String childId) async {
    emit(state.copyWith(status: KidsStatus.loading, clearMessages: true));
    final result = await _repository.allowedCategories(childId);
    result.when(
      success: (items) => emit(
        state.copyWith(
          status: KidsStatus.loaded,
          overview: {...state.overview, 'allowedCategories': items},
        ),
      ),
      failure: (error) => emit(
        state.copyWith(
          status: KidsStatus.failure,
          errorMessage: UserErrorMessage.from(error),
        ),
      ),
    );
  }

  Future<bool> saveAllowedCategories(
    String childId,
    List<int> categoryIds,
  ) async {
    emit(state.copyWith(status: KidsStatus.actionLoading, clearMessages: true));
    final result = await _repository.saveAllowedCategories(
      childId,
      categoryIds,
    );
    return result.when(
      success: (_) {
        emit(
          state.copyWith(
            status: KidsStatus.loaded,
            successMessage: 'Categorias permitidas actualizadas.',
          ),
        );
        return true;
      },
      failure: (error) {
        emit(
          state.copyWith(
            status: KidsStatus.loaded,
            errorMessage: UserErrorMessage.from(error),
          ),
        );
        return false;
      },
    );
  }
}
