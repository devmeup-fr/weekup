import 'package:flutter/material.dart';

class CardInfos extends StatelessWidget {
  final String? title;
  final Widget? testButton;
  final List<Widget> children;
  final double elevation;
  final bool withoutPadding;

  const CardInfos(
      {super.key,
      this.title,
      this.testButton,
      required this.children,
      this.elevation = 3,
      this.withoutPadding = false});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                  child: Container(
                      padding: withoutPadding
                          ? null
                          : const EdgeInsets.only(left: 8, right: 8, top: 8),
                      child: Text(
                          softWrap: true,
                          title ?? '',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)))),
              if (testButton != null)
                Container(
                  child: testButton,
                ),
            ],
          ),
          Padding(
              padding:
                  withoutPadding ? EdgeInsets.zero : const EdgeInsets.all(8),
              child: Column(children: children))
        ],
      ),
    );
  }
}
