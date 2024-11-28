int getFahrenheitFromCelsius(num value) {
  return (value * 9 / 5).round() + 32;
}

int getCelsiusFromFahrenheit(num value) {
  return ((value - 32) * 5 / 9).round();
}
