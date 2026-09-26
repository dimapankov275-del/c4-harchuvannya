import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const version = '1.0.0';
  const build = '16';

  test('v1.0 release metadata is consistent', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final buildWorkflow = File('.github/workflows/build.yml').readAsStringSync();
    final releaseWorkflow =
        File('.github/workflows/release-installers.yml').readAsStringSync();
    final installer =
        File('installer/windows/C4_Harchuvannya.iss').readAsStringSync();
    final policy = Map<String, dynamic>.from(
      jsonDecode(File('update-policy.json').readAsStringSync()) as Map,
    );

    expect(pubspec, contains('version: $version+$build'));
    expect(policy['version'], version);

    for (final text in <String>[buildWorkflow, releaseWorkflow]) {
      expect(text, contains('C4_Harchuvannya_v${version}_Android.apk'));
      expect(text, contains('C4_Harchuvannya_v${version}_Setup.exe'));
      expect(text, contains('C4_Harchuvannya_v${version}_macOS.dmg'));
      expect(text, isNot(contains('C4_Harchuvannya_v0.9.0_')));
    }

    expect(installer, contains('#define MyAppVersion "$version"'));
    expect(installer, contains('C4_Harchuvannya_v${version}_Setup'));
    expect(releaseWorkflow, contains('body_path: CHANGELOG_v1.0.md'));
    expect(releaseWorkflow, contains('Validate release tag'));
  });

  test('v1.0 update policy remains non-mandatory', () {
    final policy = Map<String, dynamic>.from(
      jsonDecode(File('update-policy.json').readAsStringSync()) as Map,
    );
    expect(policy['mandatory'], isFalse);
    expect(policy['minimumSupportedVersion'], '0.5.0');
  });
}
