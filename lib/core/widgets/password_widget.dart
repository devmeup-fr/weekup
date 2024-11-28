import 'package:flutter/material.dart';

import '../utils/localization_util.dart';

class PasswordWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function? submitForm;

  const PasswordWidget({super.key, required this.controller, this.submitForm});

  @override
  _PasswordWidgetState createState() => _PasswordWidgetState();
}

class _PasswordWidgetState extends State<PasswordWidget> {
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            obscureText: _obscureText,
            decoration: InputDecoration(
              filled: true,
              labelText: context.translate('auth.password'),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            onFieldSubmitted: (value) {
              if (widget.submitForm != null) {
                widget.submitForm!(context);
              }
            },
          ),
        ),
      ],
    );
  }
}
