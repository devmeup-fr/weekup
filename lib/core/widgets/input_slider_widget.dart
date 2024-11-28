import 'package:flutter/material.dart';

import '../models/option_select_model.dart';
import '../utils/localization_util.dart';

class InputSliderWidget extends StatefulWidget {
  final bool disabled;
  final String? title;
  final ValueNotifier valueNotifier;
  final List<OptionSelect> items;

  const InputSliderWidget({
    super.key,
    this.disabled = false,
    required this.title,
    required this.valueNotifier,
    required this.items,
  });

  @override
  State<InputSliderWidget> createState() => _InputSliderWidgetState();
}

class _InputSliderWidgetState extends State<InputSliderWidget> {
  late double _selectedValue;

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
        const SizedBox(width: 20),
        Expanded(
          child: Slider(
            value: _selectedValue, // Assumption: T is double
            min: widget.items.first.value as double,
            max: widget.items.last.value as double,
            divisions: widget.items.length - 1,
            label: context.translate(widget.items
                    .where((element) => element.value == _selectedValue)
                    .firstOrNull
                    ?.label ??
                ''),
            onChanged: !widget.disabled
                ? (double value) {
                    setState(() {
                      _selectedValue = value;
                      widget.valueNotifier.value = value;
                    });
                  }
                : null,
          ),
        ),
      ],
    );
  }
}
