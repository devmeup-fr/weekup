import 'package:flutter/material.dart';

class GoBackButtonWidget extends StatelessWidget {
  final Function? goBackHandler;
  final bool white;

  const GoBackButtonWidget({super.key, this.goBackHandler, this.white = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        if (goBackHandler != null) {
          goBackHandler!();
        }
      },
      icon: Icon(Icons.chevron_left_rounded,
          color: white ? Colors.white : Colors.black),
    );
  }
}
