import 'package:flutter/material.dart';

class ClickableWidget extends StatelessWidget {
  final void Function()? onClick;
  final Widget child;
  final bool inkwell;
  final Color hoverColor;
  final Color? focusColor;
  final Color? highlightColor;
  final Color? splashColor;

  const ClickableWidget(
      {super.key,
      this.onClick,
      required this.child,
      this.inkwell = true,
      this.focusColor = Colors.transparent,
      this.hoverColor = Colors.transparent,
      this.highlightColor = Colors.transparent,
      this.splashColor = Colors.transparent});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: inkwell
            ? InkWell(
                onTap: onClick,
                hoverColor: hoverColor,
                focusColor: focusColor,
                highlightColor: highlightColor,
                splashColor: splashColor,
                child: child)
            : GestureDetector(onTap: onClick, child: child));
  }
}
