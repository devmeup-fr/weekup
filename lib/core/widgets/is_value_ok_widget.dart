import 'package:flutter/material.dart';

class IsValueOk extends StatelessWidget {
  final bool value;

  const IsValueOk({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return value
        ? Text('OK', style: Theme.of(context).textTheme.labelMedium)
        : Icon(color: Theme.of(context).colorScheme.error, Icons.close);
  }
}
