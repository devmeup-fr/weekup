import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VersionAppWidget extends StatefulWidget {
  const VersionAppWidget({super.key});

  @override
  State<VersionAppWidget> createState() => _VersionAppWidgetState();
}

class _VersionAppWidgetState extends State<VersionAppWidget> {
  late PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "v${_packageInfo.version}+${_packageInfo.buildNumber}",
          style: TextStyle(color: Theme.of(context).colorScheme.secondary),
        ),
      ],
    );
  }
}
