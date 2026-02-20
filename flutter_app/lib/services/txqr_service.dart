import 'package:flutter/services.dart';

/// Dart-side wrapper around the Go txqr decoder exposed via MethodChannel.
class TxqrService {
  static const _channel = MethodChannel('com.divan.txqr/decoder');

  /// Feed a single QR frame string to the Go decoder.
  /// Returns null on success, or an error message string.
  Future<String?> decode(String data) async {
    final result = await _channel.invokeMethod<String>('decode', data);
    return result;
  }

  /// Whether the decoder has collected enough frames to reconstruct the data.
  Future<bool> isCompleted() async {
    final result = await _channel.invokeMethod<bool>('isCompleted');
    return result ?? false;
  }

  /// The fully decoded payload (only valid after [isCompleted] returns true).
  Future<String> getData() async {
    final result = await _channel.invokeMethod<String>('getData');
    return result ?? '';
  }

  /// Current decoding progress as a percentage (0-100).
  Future<int> getProgress() async {
    final result = await _channel.invokeMethod<int>('getProgress');
    return result ?? 0;
  }

  /// Human-readable average read speed, e.g. "12.3 KB/s".
  Future<String> getSpeed() async {
    final result = await _channel.invokeMethod<String>('getSpeed');
    return result ?? '';
  }

  /// Human-readable total scan time, e.g. "3.2s".
  Future<String> getTotalTime() async {
    final result = await _channel.invokeMethod<String>('getTotalTime');
    return result ?? '';
  }

  /// Reset the decoder for a new scanning session.
  Future<void> reset() async {
    await _channel.invokeMethod<void>('reset');
  }
}
