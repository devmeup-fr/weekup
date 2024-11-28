import 'package:flutter/material.dart';

import '../models/option_select_model.dart';
import '../utils/localization_util.dart';

class InputSelectWidget<T> extends StatefulWidget {
  final bool disabled;
  final String? title;
  final ValueNotifier<T> valueNotifier;
  final List<OptionSelect<T>> items;

  const InputSelectWidget({
    super.key,
    this.disabled = false,
    required this.title,
    required this.valueNotifier,
    required this.items,
  });

  @override
  State<InputSelectWidget<T>> createState() => _InputSelectWidgetState<T>();
}

class _InputSelectWidgetState<T> extends State<InputSelectWidget<T>> {
  late T _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.valueNotifier.value;
    widget.valueNotifier.addListener(_handleValueChanged);
  }

  @override
  void dispose() {
    widget.valueNotifier.removeListener(_handleValueChanged);
    super.dispose();
  }

  void _handleValueChanged() {
    setState(() {
      _selectedValue = widget.valueNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(widget.title ?? ''),
        const SizedBox(
          width: 20,
        ),
        DropdownButton<T>(
          value: _selectedValue,
          items: widget.items.map((OptionSelect<T> option) {
            return DropdownMenuItem<T>(
              value: option.value,
              child: Text(context.translate(option.label)),
            );
          }).toList(),
          onChanged: !widget.disabled
              ? (T? newValue) {
                  if (newValue != null) {
                    widget.valueNotifier.value = newValue;
                  }
                }
              : null,
        ),
      ],
    );
  }
}
