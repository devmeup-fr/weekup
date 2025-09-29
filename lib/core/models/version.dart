import 'package:flutter/foundation.dart';

import '../utils/type_util.dart';

class Version {
  final int majorVersion;
  final int minorVersion;
  final int revision;
  final int build;

  Version({
    required this.majorVersion,
    required this.minorVersion,
    required this.revision,
    required this.build,
  });

  void printAttributes() {
    debugPrint('*******************************************');
    debugPrint('VERSION MODEL');
    debugPrint('majorVersion: $majorVersion,');
    debugPrint('minorVersion: $minorVersion,');
    debugPrint('revision: $revision,');
    debugPrint('build: $build,');
    debugPrint('*******************************************');
  }

  static Version fromUint8List(Uint8List frame) {
    int index = 0;

    return Version(
      revision: frame[index++],
      build: frame[index++],
      minorVersion: frame[index++],
      majorVersion: frame[index++],
    );
  }

  static Uint8List toUint8List(Version version) {
    List<int> list = [];

    list.add(version.revision);
    list.add(version.build);
    list.add(version.minorVersion);
    list.add(version.majorVersion);

    return Uint8List.fromList(list);
  }

  @override
  String toString() {
    String majorVersionString = getHexStringFromUint8List(
        Uint8List.fromList([majorVersion]),
        onlyRadix: true,
        separator: '',
        padLeft: 0);
    String minorVersionString = getHexStringFromUint8List(
        Uint8List.fromList([minorVersion]),
        onlyRadix: true,
        separator: '',
        padLeft: 0);
    String buildString = getHexStringFromUint8List(Uint8List.fromList([build]),
        onlyRadix: true, separator: '', padLeft: 0);
    String revisionString = getHexStringFromUint8List(
        Uint8List.fromList([revision]),
        onlyRadix: true,
        separator: '',
        padLeft: 0);
    return '$majorVersionString.$minorVersionString.$buildString.$revisionString';
  }
}
