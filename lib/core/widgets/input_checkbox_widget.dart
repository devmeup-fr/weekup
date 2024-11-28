import 'package:flutter/material.dart';

import 'modal_widget.dart';

class InputCheckboxWidget extends StatelessWidget {
  final ValueNotifier<bool> valueNotifier;
  final String? title;
  final bool disabled;
  final bool withValidation;
  final String? validationText;

  const InputCheckboxWidget({
    super.key,
    required this.valueNotifier,
    this.title,
    this.disabled = false,
    this.withValidation = false,
    this.validationText,
  });

  void handleValidation(BuildContext context, bool value) {
    if (withValidation && !value) {
      showDialog(
        context: context,
        builder: (context) => ModalWidget(
          description: validationText,
          isWarning: true,
          onValidateHandle: () => {valueNotifier.value = value},
        ),
      );
    } else {
      valueNotifier.value = value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ValueListenableBuilder<bool>(
          valueListenable: valueNotifier,
          builder: (BuildContext context, bool isChecked, Widget? child) {
            return Checkbox(
              value: isChecked,
              onChanged: disabled
                  ? null
                  : (bool? isChecked) {
                      handleValidation(context, isChecked ?? false);
                    },
            );
          },
        ),
        Flexible(
          child: GestureDetector(
            onTap: () {
              if (!disabled) {
                handleValidation(context, !valueNotifier.value);
              }
            },
            child: Text(
              title ?? '',
              style: disabled
                  ? TextStyle(
                      color: Theme.of(context).disabledColor,
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
