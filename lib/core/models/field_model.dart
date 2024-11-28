sealed class FieldType {}

class MinMaxField extends FieldType {
  final double min;
  final double max;
  final double definedMin;
  final double definedMax;

  MinMaxField({
    required this.min,
    required this.max,
    required this.definedMin,
    required this.definedMax,
  });
}

class SwitchField extends FieldType {
  final bool defaultVal;

  SwitchField({
    required this.defaultVal,
  });
}

class EnumField extends FieldType {
  final List<String> values;
  final String defaultVal;

  EnumField({
    required this.values,
    required this.defaultVal,
  });
}

class AudioField extends FieldType {
  final int value;
  final int min = 0;
  final int max = 3;

  AudioField({
    required this.value,
  });
}

class FieldConfig<T extends FieldType> {
  final String name;
  final T type;

  FieldConfig({
    required this.name,
    required this.type,
  });
}
