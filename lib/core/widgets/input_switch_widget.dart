import 'package:flutter/material.dart';

import '../models/option_select_model.dart';
import '../utils/localization_util.dart';

class InputSwitchWidget extends StatefulWidget {
  final String? title;
  final ValueNotifier<bool> valueNotifier;
  final List<OptionSelect> items;

  const InputSwitchWidget({
    super.key,
    required this.title,
    required this.valueNotifier,
    required this.items,
  });

  @override
  State<InputSwitchWidget> createState() => _InputSwitchWidgetState();
}

class _InputSwitchWidgetState extends State<InputSwitchWidget> {
  late bool _selectedValue;

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
          child: Row(
            children: [
              if (widget.items.isNotEmpty)
                Expanded(
                    child: Text(
                  textAlign: TextAlign.center,
                  context.translate(widget.items[0].label),
                )),
              Expanded(
                child: Switch(
                  value: _selectedValue,
                  onChanged: (bool value) {
                    setState(() {
                      _selectedValue = value;
                      widget.valueNotifier.value = value;
                    });
                  },
                ),
              ),
              if (widget.items.isNotEmpty)
                Expanded(
                    child: Text(
                  textAlign: TextAlign.center,
                  context.translate(widget.items[1].label),
                )),
            ],
          ),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}
