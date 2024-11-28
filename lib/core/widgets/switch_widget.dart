import 'package:flutter/material.dart';

import '/core/widgets/title_widget.dart';

class SwitchOptionWidget extends StatelessWidget {
  final String title;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;
  final double paddingIconRight;

  const SwitchOptionWidget({
    super.key,
    required this.title,
    required this.isEnabled,
    required this.onChanged,
    this.paddingIconRight = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TitleWidget(
          title: title,
          isError: false,
          isDisabled: false,
        ),
        const Spacer(),
        Switch(
          value: isEnabled,
          onChanged: onChanged,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }
}
