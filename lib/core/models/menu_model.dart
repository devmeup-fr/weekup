import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class MenuModel {
  final String label;
  final IconData icon;
  final Widget screen;

  const MenuModel({required this.label, required this.icon, required this.screen});
}
