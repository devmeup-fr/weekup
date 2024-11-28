import 'dart:convert';

import 'package:crypto/crypto.dart';

String encryptStringToMD5(String input, String encodeKey) {
  var bytes = utf8.encode(input + encodeKey);
  var digest = md5.convert(bytes);
  return digest.toString().toUpperCase();
}

String generateKeyString(String md5String) {
  return "${md5String.substring(3, 7)}-${md5String.substring(9, 13)}";
}
