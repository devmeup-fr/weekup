import 'package:flutter/material.dart';

class ErrorTextWidget extends StatelessWidget {
  final String text;

  const ErrorTextWidget({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}
