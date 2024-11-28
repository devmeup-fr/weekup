import 'package:flutter/material.dart';

import '../utils/localization_util.dart';

class ModalWidget extends StatelessWidget {
  final String? title;
  final Icon? iconTitle;
  final bool titleColumn;
  final Widget? content;
  final String? description;
  final String? validationText;
  final Function? onValidateHandle;
  final String? cancelText;
  final Function? onCancelHandle;
  final List<Widget>? actions;
  final bool isWarning;
  final bool isLoading;

  const ModalWidget(
      {super.key,
      this.title,
      this.iconTitle,
      this.titleColumn = false,
      this.content,
      this.description,
      this.validationText,
      this.onValidateHandle,
      this.cancelText,
      this.onCancelHandle,
      this.actions,
      this.isWarning = false,
      this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (onCancelHandle != null) {
          onCancelHandle!();
        }
      },
      child: AlertDialog(
        title: getTitleWidget(context),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              content ??
                  Text(
                    context.translate(description ?? ''),
                    style: TextStyle(color: Theme.of(context).primaryColor),
                  ),
            ],
          ),
        ),
        actions: actions ??
            [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onCancelHandle != null) onCancelHandle!();
                },
                child: Text(
                  cancelText ?? context.translate('common.cancel'),
                  style: TextStyle(
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ),
              if (onValidateHandle != null)
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          if (onValidateHandle != null) {
                            onValidateHandle!();
                          } else {
                            Navigator.of(context).pop();
                          }
                        },
                  child: Text(
                    validationText ?? context.translate('common.validate'),
                    style: TextStyle(
                      color: isLoading
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
            ],
      ),
    );
  }

  Widget getTitleWidget(BuildContext context) {
    if (titleColumn) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconTitle ??
              Icon(
                Icons.warning,
                color: Theme.of(context).colorScheme.primary,
              ),
          const SizedBox(width: 8),
          Text(title ?? (isWarning ? context.translate('common.warning') : ''),
              textAlign: TextAlign.center),
        ],
      );
    }
    return Row(
      children: [
        iconTitle ??
            Icon(
              Icons.warning,
              color: Theme.of(context).colorScheme.primary,
            ),
        const SizedBox(width: 8),
        Expanded(
            child: Text(title ??
                (isWarning ? context.translate('common.warning') : ''))),
      ],
    );
  }
}
