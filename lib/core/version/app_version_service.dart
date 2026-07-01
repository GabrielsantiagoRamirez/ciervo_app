import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  PackageInfo? _info;

  Future<PackageInfo> load() async {
    return _info ??= await PackageInfo.fromPlatform();
  }

  Future<String> label() async {
    final info = await load();
    return 'v${info.version} (${info.buildNumber})';
  }

  Future<int> buildNumber() async {
    final info = await load();
    return int.tryParse(info.buildNumber) ?? 0;
  }
}
