import 'package:flutter/material.dart';

import '/core/widgets/title_widget.dart';
import '/core/widgets/value_widget.dart';

class RowInfos extends StatelessWidget {
  final String? title;
  final Widget? child;
  final List<Widget>? children;
  final bool isError;
  final bool isDisabled;
  final bool twoLines;
  final bool isFlexible;
  final bool isSpaceBetween;
  final MainAxisAlignment mainAxisAlignmentRow;
  final EdgeInsetsGeometry? paddingContainer;

  RowInfos(
      {super.key,
      this.title,
      this.child,
      this.children,
      this.twoLines = false,
      this.isError = false,
      this.isDisabled = false,
      this.isFlexible = true,
      this.isSpaceBetween = false,
      this.mainAxisAlignmentRow = MainAxisAlignment.start,
      this.paddingContainer});

  final GlobalKey _containerKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Container(
        key: _containerKey,
        padding: paddingContainer,
        child: twoLines
            ? Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleWidget(
                      title: title, isError: isError, isDisabled: isDisabled),
                  ValueWidget(
                      children: children,
                      child: child,
                      mainAxisAlignmentRow: mainAxisAlignmentRow),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  isFlexible
                      ? Flexible(
                          child: TitleWidget(
                              title: title,
                              isError: isError,
                              isDisabled: isDisabled),
                        )
                      : TitleWidget(
                          title: title,
                          isError: isError,
                          isDisabled: isDisabled),
                  if (isSpaceBetween) const Spacer(),
                  isFlexible
                      ? Flexible(
                          flex: 0,
                          child: ValueWidget(
                              children: children,
                              child: child,
                              mainAxisAlignmentRow: mainAxisAlignmentRow))
                      : ValueWidget(
                          children: children,
                          child: child,
                          mainAxisAlignmentRow: mainAxisAlignmentRow),
                ],
              ));
  }
}
