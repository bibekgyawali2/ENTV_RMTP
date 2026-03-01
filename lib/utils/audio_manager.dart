import 'package:flutter/services.dart';

class AudioManager {
  static const MethodChannel _channel = MethodChannel(
    'com.example.tv_app/audio',
  );

  static Future<void> setMicrophoneMute(bool mute) async {
    try {
      await _channel.invokeMethod('setMicrophoneMute', {'mute': mute});
    } catch (e) {
      print('Failed to set microphone mute: $e');
    }
  }

  static Future<bool> isMicrophoneMute() async {
    try {
      final bool? isMuted = await _channel.invokeMethod<bool>(
        'isMicrophoneMute',
      );
      return isMuted ?? false;
    } catch (e) {
      print('Failed to get microphone mute status: $e');
      return false;
    }
  }
}
