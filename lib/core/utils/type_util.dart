import 'dart:typed_data';

import 'extension_util.dart';

int getIntFromStringHex(String value) {
  value = value.trim().toUpperCase();
  return int.parse(value, radix: 16);
}

Uint8List getUint8ListFromListStringHex(String value) {
  return Uint8List.fromList(value
      .splitByLength(2)
      .map((value) => getIntFromStringHex(value))
      .toList());
}

Uint8List getUint8ListFromInt16(int value) {
  ByteData buffer = ByteData(2);
  buffer.setUint16(0, value, Endian.little);

  return Uint8List.view(buffer.buffer);
}

Uint8List getUint8ListFromInt32(int value) {
  ByteData buffer = ByteData(4);
  buffer.setUint32(0, value, Endian.little);

  return Uint8List.view(buffer.buffer);
}

Uint8List getUint8ListFromInt64(int value) {
  ByteData buffer = ByteData(8);
  buffer.setUint64(0, value, Endian.little);

  return Uint8List.view(buffer.buffer);
}

Uint8List getUint8ListFromFloat32(double value) {
  ByteData buffer = ByteData(4);
  buffer.setFloat32(0, value, Endian.little);

  return Uint8List.view(buffer.buffer);
}

Uint8List getUint8ListFromFloat64(double value) {
  ByteData buffer = ByteData(8);
  buffer.setFloat64(0, value, Endian.little);

  return Uint8List.view(buffer.buffer);
}

Uint8List getUint8ListFromDateTime(DateTime date) {
  double value = date.millisecondsSinceEpoch / 1000;
  return getUint8ListFromInt32(value.round());
}

int getInt16FromUint8List(Uint8List list, {unsigned = true}) {
  if (list.length < 2) {
    throw ArgumentError("The list must contain at least 2 elements");
  }

  ByteData buffer = ByteData(2);
  buffer.setUint8(0, list[0]);
  buffer.setUint8(1, list[1]);

  int value = buffer.getInt16(0, Endian.little);

  return unsigned ? value.toUnsigned(16) : value;
}

int getInt32FromUint8List(Uint8List list, {unsigned = true}) {
  if (list.length < 4) {
    throw ArgumentError("The list must contain at least 4 elements");
  }

  ByteData buffer = ByteData(4);
  buffer.setUint8(0, list[0]);
  buffer.setUint8(1, list[1]);
  buffer.setUint8(2, list[2]);
  buffer.setUint8(3, list[3]);

  int value = buffer.getInt32(0, Endian.little);

  return unsigned ? value.toUnsigned(32) : value;
}

int getInt64FromUint8List(Uint8List list, {unsigned = true}) {
  if (list.length < 8) {
    throw ArgumentError("The list must contain at least 8 elements");
  }

  ByteData buffer = ByteData(8);
  buffer.setUint8(0, list[0]);
  buffer.setUint8(1, list[1]);
  buffer.setUint8(2, list[2]);
  buffer.setUint8(3, list[3]);
  buffer.setUint8(4, list[4]);
  buffer.setUint8(5, list[5]);
  buffer.setUint8(6, list[6]);
  buffer.setUint8(7, list[7]);

  int value = buffer.getInt64(0, Endian.little);

  return unsigned ? value.toUnsigned(64) : value;
}

String? getStringFromUint8List(Uint8List list) {
  if (list.first == 0x00) return null;

  final nullIndex = list.indexOf(0x00);

  if (nullIndex != -1) {
    list = list.sublist(0, nullIndex);
  }

  return String.fromCharCodes(list);
}

double getFloatFromUint8List(Uint8List list) {
  if (list.length < 4) {
    throw ArgumentError("The list must contain at least 4 elements");
  }

  ByteData buffer = ByteData(4);
  buffer.setUint8(0, list[0]);
  buffer.setUint8(1, list[1]);
  buffer.setUint8(2, list[2]);
  buffer.setUint8(3, list[3]);

  return buffer.getFloat32(0, Endian.little);
}

double getFloat64FromUint8List(Uint8List list) {
  if (list.length < 8) {
    throw ArgumentError("The list must contain at least 4 elements");
  }

  ByteData buffer = ByteData(8);
  buffer.setUint8(0, list[0]);
  buffer.setUint8(1, list[1]);
  buffer.setUint8(2, list[2]);
  buffer.setUint8(3, list[3]);
  buffer.setUint8(4, list[4]);
  buffer.setUint8(5, list[5]);
  buffer.setUint8(6, list[6]);
  buffer.setUint8(7, list[7]);

  return buffer.getFloat64(0, Endian.little);
}

DateTime? getDateTimeFromUint8List(Uint8List list) {
  if (list.first == 0x00) return null;

  return DateTime.fromMillisecondsSinceEpoch(
      getInt32FromUint8List(list) * 1000);
}

String getHexStringFromUint8List(Uint8List list,
    {onlyRadix = false, separator = ' ', padLeft = 2}) {
  return list.map((e) {
    String radix = e.toRadixString(16).toUpperCase().padLeft(padLeft, '0');
    return onlyRadix ? radix : '0x$radix';
  }).join(separator);
}

String getBinaryStringFromInt(int value, {int length = 8}) {
  return value.toRadixString(2).padLeft(length, '0');
}

List<int> getListIntFromDateTime(DateTime? date) {
  if (date != null) {
    return getUint8ListFromDateTime(date).toList();
  } else {
    return [0x00, 0x00, 0x00, 0x00];
  }
}

Uint8List getUint8ListFromString(String? value, {int? length}) {
  List<int> list = value?.codeUnits ?? [];

  int followedLength = 0;
  if (length != null) {
    followedLength = length - (value?.length ?? 0);
  }

  return Uint8List.fromList(
      list.followedBy(List.generate(followedLength, (e) => 0x00)).toList());
}

String formatDuration(int seconds) {
  final Duration duration = Duration(seconds: seconds);
  String twoDigits(int n) => n.toString().padLeft(2, "0");

  String formattedDuration = '';

  if (duration.inDays > 0) {
    formattedDuration += "${duration.inDays}.";
  }
  formattedDuration += "${twoDigits(duration.inHours.remainder(24))}:";
  formattedDuration += "${twoDigits(duration.inMinutes.remainder(60))}:";
  formattedDuration += twoDigits(duration.inSeconds.remainder(60));

  return formattedDuration;
}
