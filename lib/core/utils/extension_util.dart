import 'dart:async';
import 'dart:typed_data';

import 'package:intl/intl.dart';

extension IterableExtension<T> on Iterable<T> {
  bool doesNotContain(T element) => !contains(element);

  List<E> mapToList<E>(E Function(T element) convert) => map(convert).toList();

  List<T> whereToList(bool Function(T element) test) => where(test).toList();
}

extension ListExtension<T> on List<T> {
  List<T> spaced(T element, {bool addLast = false, bool addFirst = false}) {
    final result = <T>[if (addFirst) element];
    for (T t in this) {
      result.add(t);
      result.add(element);
    }
    if (!addLast && isNotEmpty) result.removeLast();
    return result;
  }

  List<T> ifEmptyAdd(T element) => isEmpty ? [element] : this;

  List<T> sortBy(Comparable Function(T) getAttribute, {bool asc = true}) {
    List<T> array = this;
    array.sort((a, b) {
      final dynamic aValue = getAttribute(a);
      final dynamic bValue = getAttribute(b);

      if (aValue == null && bValue == null) return 0;
      if (aValue == null) return 1;
      if (bValue == null) return -1;

      int comparison = aValue.compareTo(bValue);

      return asc ? comparison : -comparison;
    });

    return array;
  }
}

extension NullableListExtension<T> on List<T>? {
  bool get isNullOrEmpty => this?.isEmpty ?? true;
}

extension StringExtension on String {
  String capitalize() => '${this[0].toUpperCase()}${substring(1)}';

  List<String> splitByLength(int length) {
    List<String> parts = [];
    for (int i = 0; i < this.length; i += length) {
      parts.add(substring(i, i + length));
    }
    return parts;
  }
}

extension DateFormatExtension on DateTime {
  String formatDate() => DateFormat('dd/MM/yyyy HH:mm:ss').format(this);
  String formatDateWS(local) =>
      DateFormat('EEE dd/MM/yyyy HH:mm', local).format(toLocal());
  String formatDateDayMonth() => DateFormat('dd/MM').format(this);
  String formatDateDay() => DateFormat('dd/MM/yyyy').format(this);
  String formatDateMin(local) => DateFormat('EEE d MMM', local).format(this);
  String formatDateHour() => DateFormat('HH:mm:ss').format(this);
  String formatTime() => DateFormat('HH:mm').format(toLocal());
  String formatDayOfWeek() => DateFormat('dddd').format(this);
  String formatDayStringOfWeek() => DateFormat('EEEE').format(this);

  String formatDateToJson() =>
      DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(this);
}

extension Uint8ListEquality on Uint8List {
  bool equals(Uint8List other) {
    if (length != other.length) return false;
    for (int i = 0; i < length; i++) {
      if (this[i] != other[i]) return false;
    }
    return true;
  }
}

// It is essentially a stream but:
//  1. we cache the latestValue of the stream
//  2. the "latestValue" is re-emitted whenever the stream is listened to
class StreamControllerReemit<T> {
  T? _latestValue;

  final StreamController<T> _controller = StreamController<T>.broadcast();

  StreamControllerReemit({T? initialValue}) : _latestValue = initialValue;

  Stream<T> get stream {
    return _latestValue != null
        ? _controller.stream.newStreamWithInitialValue(_latestValue as T)
        : _controller.stream;
  }

  T? get value => _latestValue;

  void add(T newValue) {
    _latestValue = newValue;
    _controller.add(newValue);
  }

  Future<void> close() {
    return _controller.close();
  }
}

// return a new stream that immediately emits an initial value
extension _StreamNewStreamWithInitialValue<T> on Stream<T> {
  Stream<T> newStreamWithInitialValue(T initialValue) {
    return transform(_NewStreamWithInitialValueTransformer(initialValue));
  }
}

// Helper for 'newStreamWithInitialValue' method for streams.
class _NewStreamWithInitialValueTransformer<T>
    extends StreamTransformerBase<T, T> {
  /// the initial value to push to the new stream
  final T initialValue;

  /// controller for the new stream
  late StreamController<T> controller;

  /// subscription to the original stream
  late StreamSubscription<T> subscription;

  /// new stream listener count
  var listenerCount = 0;

  _NewStreamWithInitialValueTransformer(this.initialValue);

  @override
  Stream<T> bind(Stream<T> stream) {
    if (stream.isBroadcast) {
      return _bind(stream, broadcast: true);
    } else {
      return _bind(stream);
    }
  }

  Stream<T> _bind(Stream<T> stream, {bool broadcast = false}) {
    /////////////////////////////////////////
    /// Original Stream Subscription Callbacks
    ///

    /// When the original stream emits data, forward it to our new stream
    void onData(T data) {
      controller.add(data);
    }

    /// When the original stream is done, close our new stream
    void onDone() {
      controller.close();
    }

    /// When the original stream has an error, forward it to our new stream
    void onError(Object error) {
      controller.addError(error);
    }

    /// When a client listens to our new stream, emit the
    /// initial value and subscribe to original stream if needed
    void onListen() {
      // Emit the initial value to our new stream
      controller.add(initialValue);

      // listen to the original stream, if needed
      if (listenerCount == 0) {
        subscription = stream.listen(
          onData,
          onError: onError,
          onDone: onDone,
        );
      }

      // count listeners of the new stream
      listenerCount++;
    }

    //////////////////////////////////////
    ///  New Stream Controller Callbacks
    ///

    /// (Single Subscription Only) When a client pauses
    /// the new stream, pause the original stream
    void onPause() {
      subscription.pause();
    }

    /// (Single Subscription Only) When a client resumes
    /// the new stream, resume the original stream
    void onResume() {
      subscription.resume();
    }

    /// Called when a client cancels their
    /// subscription to the new stream,
    void onCancel() {
      // count listeners of the new stream
      listenerCount--;

      // when there are no more listeners of the new stream,
      // cancel the subscription to the original stream,
      // and close the new stream controller
      if (listenerCount == 0) {
        subscription.cancel();
        controller.close();
      }
    }

    //////////////////////////////////////
    /// Return New Stream
    ///

    // create a new stream controller
    if (broadcast) {
      controller = StreamController<T>.broadcast(
        onListen: onListen,
        onCancel: onCancel,
      );
    } else {
      controller = StreamController<T>(
        onListen: onListen,
        onPause: onPause,
        onResume: onResume,
        onCancel: onCancel,
      );
    }

    return controller.stream;
  }
}
