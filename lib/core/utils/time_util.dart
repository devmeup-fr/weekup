DateTime timeOfDayToUtc(DateTime time) {
  final nowLocal = DateTime.now();
  final localDateTime = DateTime(
    nowLocal.year,
    nowLocal.month,
    nowLocal.day,
    time.hour,
    time.minute,
  );

  final durationOffset = localDateTime.timeZoneOffset;

  return localDateTime.subtract(durationOffset);
}
