import 'package:flutter/material.dart';

class TitleWidget extends StatelessWidget {
  final String? title;
  final bool isDisabled;
  final bool isError;

  const TitleWidget({
    super.key,
    required this.title,
    this.isDisabled = false,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title != null ? "$title : " : '',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontWeight: FontWeight.w900,
            color: isDisabled
                ? Theme.of(context).disabledColor
                : isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context)
                        .colorScheme
                        .onSurface, // Adjust color here
          ),
    );
  }
}
