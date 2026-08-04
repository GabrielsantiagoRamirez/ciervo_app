from pathlib import Path

path = Path("lib/features/wallet/data/repositories/wallet_repository_impl.dart")
text = path.read_text(encoding="utf-8")

imp_old = (
    "import '../../domain/entities/resolved_wallet_user.dart';\n"
    "import '../../domain/entities/transfer_result.dart';"
)
imp_new = (
    "import '../../domain/entities/resolved_wallet_user.dart';\n"
    "import '../../domain/entities/transfer_directory_entry.dart';\n"
    "import '../../domain/entities/transfer_result.dart';"
)
if imp_old not in text:
    raise SystemExit("import block not found")
text = text.replace(imp_old, imp_new, 1)

old = """  @override
  Future<Result<ResolvedWalletUser>> resolveUser(String ciervoUserCode) async {
    try {
      return Success(
        (await _remoteDataSource.resolveUser(ciervoUserCode)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<TransferResult>> transfer({"""

new = """  @override
  Future<Result<ResolvedWalletUser>> resolveUser(String ciervoUserCode) async {
    try {
      return Success(
        (await _remoteDataSource.resolveUser(ciervoUserCode)).toDomain(),
      );
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<TransferDirectoryEntry>>> transferContacts({
    int take = 50,
  }) async {
    try {
      final items = await _remoteDataSource.transferContacts(take: take);
      return Success(items.map((e) => e.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<List<TransferDirectoryEntry>>> transferFavorites() async {
    try {
      final items = await _remoteDataSource.transferFavorites();
      return Success(items.map((e) => e.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<void>> addTransferFavorite({
    String? targetUserId,
    String? targetCiervoUserCode,
    String? targetUsername,
  }) => _void(
    () => _remoteDataSource.addTransferFavorite(
      targetUserId: targetUserId,
      targetCiervoUserCode: targetCiervoUserCode,
      targetUsername: targetUsername,
    ),
  );

  @override
  Future<Result<void>> removeTransferFavorite(String favoriteUserId) =>
      _void(() => _remoteDataSource.removeTransferFavorite(favoriteUserId));

  @override
  Future<Result<List<TransferDirectoryEntry>>> transferRecent({
    int take = 20,
  }) async {
    try {
      final items = await _remoteDataSource.transferRecent(take: take);
      return Success(items.map((e) => e.toDomain()).toList());
    } catch (error) {
      return Failure(ErrorMapper.fromObject(error));
    }
  }

  @override
  Future<Result<TransferResult>> transfer({"""

if old not in text:
    raise SystemExit("resolve/transfer block not found")
path.write_text(text.replace(old, new, 1), encoding="utf-8")
print("patched ok")
