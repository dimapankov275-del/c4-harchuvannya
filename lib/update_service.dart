import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.tag,
    required this.downloadUrl,
    required this.releasePageUrl,
    required this.minimumSupportedVersion,
    required this.mandatory,
    required this.notes,
  });

  final String currentVersion;
  final String latestVersion;
  final String tag;
  final String downloadUrl;
  final String releasePageUrl;
  final String minimumSupportedVersion;
  final bool mandatory;
  final List<String> notes;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'tag': tag,
        'downloadUrl': downloadUrl,
        'releasePageUrl': releasePageUrl,
        'minimumSupportedVersion': minimumSupportedVersion,
        'mandatory': mandatory,
        'notes': notes,
      };

  static AppUpdateInfo? fromJson(Map<String, dynamic> map) {
    final latest = map['latestVersion']?.toString() ?? '';
    final tag = map['tag']?.toString() ?? '';
    if (latest.isEmpty || tag.isEmpty) return null;
    final rawNotes = (map['notes'] as List?) ?? const <dynamic>[];
    return AppUpdateInfo(
      currentVersion: map['currentVersion']?.toString() ?? '',
      latestVersion: latest,
      tag: tag,
      downloadUrl: map['downloadUrl']?.toString() ?? '',
      releasePageUrl: map['releasePageUrl']?.toString() ?? '',
      minimumSupportedVersion: map['minimumSupportedVersion']?.toString() ?? '',
      mandatory: map['mandatory'] == true,
      notes: rawNotes.map((dynamic e) => e.toString()).where((String e) => e.trim().isNotEmpty).toList(),
    );
  }
}

class UpdateService {
  static const String _owner = 'dimapankov275-del';
  static const String _repo = 'c4-harchuvannya';
  static const String _latestReleaseUrl = 'https://github.com/$_owner/$_repo/releases/latest';

  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  Future<AppUpdateInfo?> checkForUpdate({required String currentVersion}) async {
    final tag = await _resolveLatestTag(currentVersion);
    if (tag == null || tag.isEmpty) return null;
    final latestVersion = tag.startsWith('v') ? tag.substring(1) : tag;
    if (compareVersions(latestVersion, currentVersion) <= 0) return null;

    final releaseBase = 'https://github.com/$_owner/$_repo/releases/download/$tag';
    final releasePage = 'https://github.com/$_owner/$_repo/releases/tag/$tag';
    var minimumSupported = currentVersion;
    var mandatory = false;
    var notes = <String>[];

    try {
      final policyResponse = await http
          .get(
            Uri.parse('$releaseBase/update-policy.json'),
            headers: <String, String>{'User-Agent': 'C4-Harchuvannya/$currentVersion'},
          )
          .timeout(const Duration(seconds: 12));
      if (policyResponse.statusCode >= 200 && policyResponse.statusCode < 300) {
        final policy = Map<String, dynamic>.from(jsonDecode(policyResponse.body) as Map);
        minimumSupported = policy['minimumSupportedVersion']?.toString() ?? currentVersion;
        mandatory = policy['mandatory'] == true || compareVersions(currentVersion, minimumSupported) < 0;
        final rawNotes = (policy['notes'] as List?) ?? const <dynamic>[];
        notes = rawNotes.map((dynamic e) => e.toString()).where((String e) => e.trim().isNotEmpty).toList();
      }
    } catch (_) {
      // Release policy is optional. A normal update can still be offered.
    }

    return AppUpdateInfo(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      tag: tag,
      downloadUrl: '$releaseBase/${_assetName(latestVersion)}',
      releasePageUrl: releasePage,
      minimumSupportedVersion: minimumSupported,
      mandatory: mandatory,
      notes: notes,
    );
  }

  Future<String?> _resolveLatestTag(String currentVersion) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(_latestReleaseUrl))
        ..followRedirects = false
        ..headers['User-Agent'] = 'C4-Harchuvannya/$currentVersion';
      final streamed = await client.send(request).timeout(const Duration(seconds: 12));
      final status = streamed.statusCode;
      if (status == 301 || status == 302 || status == 303 || status == 307 || status == 308) {
        final location = streamed.headers['location'];
        if (location == null || location.isEmpty) return null;
        final resolved = Uri.parse(_latestReleaseUrl).resolve(location);
        final segments = resolved.pathSegments;
        final tagIndex = segments.indexOf('tag');
        if (tagIndex >= 0 && tagIndex + 1 < segments.length) return segments[tagIndex + 1];
      }
      return null;
    } finally {
      client.close();
    }
  }

  String _assetName(String version) {
    if (Platform.isWindows) return 'C4_Harchuvannya_v${version}_Setup.exe';
    if (Platform.isAndroid) return 'C4_Harchuvannya_v${version}_Android.apk';
    if (Platform.isMacOS) return 'C4_Harchuvannya_v${version}_macOS.dmg';
    return 'update-policy.json';
  }

  Future<void> openDownload(AppUpdateInfo info) async {
    final target = (Platform.isWindows || Platform.isAndroid || Platform.isMacOS)
        ? info.downloadUrl
        : info.releasePageUrl;
    final opened = await launchUrl(Uri.parse(target), mode: LaunchMode.externalApplication);
    if (!opened) throw StateError('Не вдалося відкрити сторінку завантаження.');
  }

  Future<void> openReleasePage(AppUpdateInfo info) async {
    final opened = await launchUrl(Uri.parse(info.releasePageUrl), mode: LaunchMode.externalApplication);
    if (!opened) throw StateError('Не вдалося відкрити сторінку релізу.');
  }

  static int compareVersions(String left, String right) {
    final a = _versionParts(left);
    final b = _versionParts(right);
    final length = a.length > b.length ? a.length : b.length;
    for (var i = 0; i < length; i++) {
      final av = i < a.length ? a[i] : 0;
      final bv = i < b.length ? b[i] : 0;
      if (av != bv) return av.compareTo(bv);
    }
    return 0;
  }

  static List<int> _versionParts(String value) {
    final clean = value.trim().replaceFirst(RegExp(r'^[vV]'), '');
    return clean
        .split('.')
        .map((String part) => int.tryParse(RegExp(r'^\d+').firstMatch(part)?.group(0) ?? '') ?? 0)
        .toList();
  }
}
