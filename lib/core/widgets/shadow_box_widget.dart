import 'package:flutter/material.dart';

class ShadowBoxWidget extends StatelessWidget {
  final Widget child;
  final double? ratio;
  final double? maxWidth;
  final double padding;
  final Offset elevation;

  const ShadowBoxWidget(
      {super.key,
      required this.child,
      this.ratio,
      this.maxWidth,
      this.padding = 20.0,
      this.elevation = const Offset(0, 3)});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
          padding: EdgeInsets.all(padding),
          child: IntrinsicHeight(
            child: Container(
              constraints: BoxConstraints(
                      minHeight: ratio == null
                          ? 0.0
                          : MediaQuery.of(context).size.height * ratio!,
                      minWidth: maxWidth == null
                          ? 0.0
                          : MediaQuery.of(context).size.width * 0.5 < 700
                              ? 700
                              : MediaQuery.of(context).size.width * 0.5,
                      maxWidth: maxWidth ?? double.infinity)
                  .normalize(),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 5,
                    blurRadius: 7,
                    offset: elevation,
                  ),
                ],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: child,
              ),
            ),
          )),
    );
  }
}
