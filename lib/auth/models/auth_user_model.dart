import 'package:flutter/material.dart';

const authRoleAdmin = 5;

class AuthUserModel {
  final int id;
  final String label;
  final int right;

  AuthUserModel({required this.id, required this.label, required this.right});

  void printAttributes() {
    debugPrint('*******************************************');
    debugPrint('VALUES AUTH USER MODEL');
    debugPrint('id : $id');
    debugPrint('label : $label');
    debugPrint('right : $right');
    debugPrint('*******************************************');
  }

  bool canShowAdvancedStats() {
    return right == authRoleAdmin;
  }

  factory AuthUserModel.fromJson(Map<String, dynamic> authUser) {
    if (authUser['user']['id'] == null) throw Exception('auth.errors.500');

    return AuthUserModel(
      id: authUser['user']['id'] ?? 0,
      label: authUser['user']['label'] ?? 0,
      right: authUser['user']['right'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {"id": id, "right": right, "label": label},
    };
  }
}
