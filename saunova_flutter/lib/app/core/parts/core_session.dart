part of '../core.dart';

extension CoreSession on Core {
  Future<void> startSession(
    int sessionLength,
    int temperature,
    int humidity,
  ) async {
    if (!_ensure) return;
    await ApiService.startSession(sessionLength, temperature, humidity);
  }

  Future<void> stopSession() async {
    if (!_ensure) return;
    await ApiService.stopSession();
  }
}
