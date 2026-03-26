import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/foundation.dart';

class VersionCheckResult {
  final bool canUpdate;
  final String localVersion;
  final String storeVersion;

  VersionCheckResult({
    required this.canUpdate,
    required this.localVersion,
    required this.storeVersion,
  });
}

class VersioningService {
  static const String appId = "com.minbertv.minber";
  static const String playStoreUrl =
      "https://play.google.com/store/apps/details?id=$appId&hl=en";

  /// Returns detailed version info instead of just a boolean
  static Future<VersionCheckResult> checkVersionStatus() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final localVersion = packageInfo.version;

      final storeVersion = await _getStoreVersion();

      if (storeVersion == null) {
        return VersionCheckResult(
            canUpdate: false,
            localVersion: localVersion,
            storeVersion: "Unknown");
      }

      bool shouldUpdate = _isVersionGreaterThan(storeVersion, localVersion);

      return VersionCheckResult(
        canUpdate: shouldUpdate,
        localVersion: localVersion,
        storeVersion: storeVersion,
      );
    } catch (e) {
      return VersionCheckResult(
          canUpdate: false, localVersion: "0.0.0", storeVersion: "0.0.0");
    }
  }

  static Future<String?> _getStoreVersion() async {
    
    try {
      final response = await http.get(Uri.parse(playStoreUrl), headers: {
        "User-Agent":
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return null;

      final body = response.body;
      final patterns = [
        r'''\[\[\["(\d+\.\d+\.\d+)"\]\]''',
        r'''AF_initDataCallback\({key:\s*'ds:5'.*?data:.*?\"(\d+\.\d+\.\d+)\"''',
        r'''\["(\d+\.\d+\.\d+)"\]''',
      ];

      for (final pattern in patterns) {
        final regex = RegExp(pattern);
        final match = regex.firstMatch(body);
        if (match != null) return match.group(1);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static bool _isVersionGreaterThan(String storeVersion, String localVersion) {
    List<int> storeParts =
        storeVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> localParts =
        localVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    int maxLength = storeParts.length > localParts.length
        ? storeParts.length
        : localParts.length;
    for (int i = 0; i < maxLength; i++) {
      int s = i < storeParts.length ? storeParts[i] : 0;
      int l = i < localParts.length ? localParts[i] : 0;
      if (s > l) return true;
      if (s < l) return false;
    }
    return false;
  }
}
