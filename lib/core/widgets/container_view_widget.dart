import 'package:flutter/material.dart';

class ContainerViewWidget extends StatelessWidget {
  final Widget child;
  final bool withoutSingleChildScrollView;

  const ContainerViewWidget(
      {super.key,
      required this.child,
      this.withoutSingleChildScrollView = false});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return !withoutSingleChildScrollView
            ? SingleChildScrollView(
                child: getContainerView(context, constraints, child),
              )
            : getContainerView(context, constraints, child);
      },
    );
  }
}

Widget getContainerView(
    BuildContext context, BoxConstraints constraints, Widget child) {
  return Center(
      child: ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: constraints.maxHeight,
      maxWidth: 600,
    ),
    child: IntrinsicHeight(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: child,
      ),
    ),
  ));
}
