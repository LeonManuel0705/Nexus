import 'package:flutter/services.dart';

class FocusModeService {
  static final FocusModeService _instance = FocusModeService._internal();
  factory FocusModeService() => _instance;
  FocusModeService._internal();

  static const MethodChannel _channel = MethodChannel('com.nexus.app/focus_mode');

  bool _isFocusModeActive = false;
  bool get isFocusModeActive => _isFocusModeActive;

  Future<bool> enableFocusMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('enableFocusMode');
      _isFocusModeActive = result ?? false;
      return _isFocusModeActive;
    } on PlatformException catch (_) {

      _isFocusModeActive = true;
      return false;
    } on MissingPluginException catch (_) {

      _isFocusModeActive = true;
      return false;
    }
  }

  Future<bool> disableFocusMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('disableFocusMode');
      _isFocusModeActive = !(result ?? true);
      return !_isFocusModeActive;
    } on PlatformException catch (_) {
      _isFocusModeActive = false;
      return false;
    } on MissingPluginException catch (_) {
      _isFocusModeActive = false;
      return false;
    }
  }

  Future<bool> hasPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestPermission');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    } on MissingPluginException catch (_) {
      return false;
    }
  }
}
