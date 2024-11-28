import 'package:flutter/material.dart';

class ValueWidget extends StatelessWidget {
  final List<Widget>? children;
  final Widget? child;
  final MainAxisAlignment mainAxisAlignmentRow;

  const ValueWidget({
    super.key,
    this.children,
    this.child,
    this.mainAxisAlignmentRow = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: mainAxisAlignmentRow,
      children: children ?? [child!],
    );
  }
}
