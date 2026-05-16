import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ios packaging uses xcframeworks without x86 simulator support', () {
    final podspec = File('ios/ffmpeg_kit_flutter_new_min_gpl.podspec')
        .readAsStringSync();
    final script = File('scripts/setup_ios.sh').readAsStringSync();

    expect(podspec, contains('.xcframework'));
    expect(
      podspec,
      contains("'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386'"),
    );
    expect(script, contains('xcodebuild -create-xcframework'));
    expect(script, isNot(contains('x86_64')));
  });
}
