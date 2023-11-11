import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/src/audio_device.dart';
import 'package:flutter_volume_controller/src/audio_device_type.dart';
import 'package:flutter_volume_controller/src/audio_session_category.dart';
import 'package:flutter_volume_controller/src/audio_stream.dart';
import 'package:flutter_volume_controller/src/constants.dart';
import 'package:flutter_volume_controller/src/platform.dart';

/// A Flutter plugin to control system volume and listen for volume changes on different platforms.
class FlutterVolumeController {
  const FlutterVolumeController._();

  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel(
    'com.yosemiteyss.flutter_volume_controller/method',
  );

  @visibleForTesting
  static const EventChannel eventChannel = EventChannel(
    'com.yosemiteyss.flutter_volume_controller/event',
  );

  @visibleForTesting
  static const EventChannel defaultAudioDeviceChannel = EventChannel(
    'com.yosemiteyss.flutter_volume_controller/default-audio-device',
  );

  /// Listener for volume change events.
  static StreamSubscription<double>? _volumeListener;

  /// Listener for default input device changes.
  static StreamSubscription<AudioDevice>? _defaultInputDeviceListener;

  /// Listener for default output device changes.
  static StreamSubscription<AudioDevice>? _defaultOutputDeviceListener;

  /// Control system UI visibility.
  /// Set to `true` to display volume slider when changing volume.
  /// This setting only works on Android and iOS.
  static bool _showSystemUI = true;

  static bool get showSystemUI => _showSystemUI;

  @Deprecated(
    'Migrate to [FlutterVolumeController.updateShowSystemUI] instead. '
    'This setter was deprecated >= 1.3.0.',
  )
  static set showSystemUI(bool isShown) {
    _showSystemUI = isShown;
  }

  static const AudioStream _defaultAudioStream = AudioStream.music;
  static const AudioSessionCategory _defaultAudioSessionCategory =
      AudioSessionCategory.ambient;

  /// Control system UI visibility.
  /// Set [isShown] to `true` to display volume slider when changing volume.
  /// This setting only works on Android and iOS.
  /// Note: this setting doesn't control the volume slider invoked by physical
  /// buttons on Android.
  static Future<void> updateShowSystemUI(bool isShown) async {
    _showSystemUI = isShown;
    // iOS: needs to update MPVolumeView visibility, otherwise pressing physical buttons
    // won't display volume slider after [showSystemUI] is reset to true.
    if (Platform.isIOS) {
      await methodChannel.invokeMethod<void>(
        MethodName.updateShowSystemUI,
        {MethodArg.showSystemUI: isShown},
      );
    }
  }

  /// Get the current volume level. From 0.0 to 1.0.
  /// Use [stream] to set the audio stream type on Android.
  static Future<double?> getVolume({
    AudioStream stream = _defaultAudioStream,
  }) async {
    final receivedValue = await methodChannel.invokeMethod<String>(
      MethodName.getVolume,
      {
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );

    return receivedValue != null ? double.parse(receivedValue) : null;
  }

  /// Set the volume level. From 0.0 to 1.0.
  /// Use [stream] to set the audio stream type on Android.
  static Future<void> setVolume(
    double volume, {
    AudioStream stream = _defaultAudioStream,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.setVolume,
      {
        MethodArg.volume: volume,
        if (Platform.isAndroid || Platform.isIOS)
          MethodArg.showSystemUI: showSystemUI,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Increase the volume level by [step]. From 0.0 to 1.0.
  /// On Android and Windows, when [step] is set to null, it will uses the
  /// default system stepping value.
  /// On iOS, macOS, Linux, if [step] is not defined, the default
  /// stepping value is set to 0.15.
  /// Use [stream] to set the audio stream type on Android.
  static Future<void> raiseVolume(
    double? step, {
    AudioStream stream = _defaultAudioStream,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.raiseVolume,
      {
        if (Platform.isAndroid || Platform.isIOS)
          MethodArg.showSystemUI: showSystemUI,
        if (step != null) MethodArg.step: step,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Decrease the volume level by [step]. From 0.0 to 1.0.
  /// On Android and Windows, when [step] is set to null, it will uses the
  /// default system stepping value.
  /// On iOS, macOS, Linux, if [step] is not defined, the default
  /// stepping value is set to 0.15.
  /// Use [stream] to set the audio stream type on Android.
  static Future<void> lowerVolume(
    double? step, {
    AudioStream stream = _defaultAudioStream,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.lowerVolume,
      {
        if (Platform.isAndroid || Platform.isIOS)
          MethodArg.showSystemUI: showSystemUI,
        if (step != null) MethodArg.step: step,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Check if the volume is muted.
  /// On Android and iOS, we check if the current volume level is already
  /// dropped to zero.
  /// On macOS, Windows, Linux, we check if the mute switch is turned on.
  /// Use [stream] to set the audio stream type on Android.
  static Future<bool?> getMute({
    AudioStream stream = _defaultAudioStream,
  }) async {
    return methodChannel.invokeMethod<bool>(
      MethodName.getMute,
      {
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Mute or unmute the volume.
  /// On Android and iOS, we either set the volume to zero or revert to the previous level.
  /// On macOS, Windows, Linux, we control the mute switch. Volume will be restored
  /// once it's unmuted.
  /// Use [stream] to set the audio stream type on Android.
  static Future<void> setMute(
    bool isMuted, {
    AudioStream stream = _defaultAudioStream,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.setMute,
      {
        MethodArg.isMuted: isMuted,
        if (Platform.isAndroid || Platform.isIOS)
          MethodArg.showSystemUI: showSystemUI,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Toggle between the volume mute and unmute state.
  /// Please refers to [setMute] for platform behaviors.
  /// Use [stream] to set the audio stream type on Android.
  static Future<void> toggleMute({
    AudioStream stream = _defaultAudioStream,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.toggleMute,
      {
        if (Platform.isAndroid || Platform.isIOS)
          MethodArg.showSystemUI: showSystemUI,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Set the default audio stream on Android.
  /// Adjusts to the audio stream whose volume should be changed by the hardware volume controls.
  /// Use [stream] to set the audio stream type on Android.
  /// Docs: https://developer.android.com/reference/android/media/AudioManager
  static Future<void> setAndroidAudioStream({
    AudioStream stream = _defaultAudioStream,
  }) async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod(
        MethodName.setAndroidAudioStream,
        {MethodArg.audioStream: stream.index},
      );
    }
  }

  /// Get the current audio stream on Android.
  static Future<AudioStream?> getAndroidAudioStream() async {
    if (Platform.isAndroid) {
      final index = await methodChannel
          .invokeMethod<int>(MethodName.getAndroidAudioStream);
      return index != null ? AudioStream.values[index] : null;
    }

    return null;
  }

  /// Set the default audio session category on iOS.
  /// Adjusts to a different set of audio behaviors.
  /// Use [category] to set the audio session category type on iOS.
  /// Docs: https://developer.apple.com/documentation/avfaudio/avaudiosession/category
  static Future<void> setIOSAudioSessionCategory({
    AudioSessionCategory category = _defaultAudioSessionCategory,
  }) async {
    if (Platform.isIOS) {
      await methodChannel.invokeMethod(
        MethodName.setIOSAudioSessionCategory,
        {MethodArg.audioSessionCategory: category.index},
      );
    }
  }

  /// Get the current audio session category on iOS.
  static Future<AudioSessionCategory?> getIOSAudioSessionCategory() async {
    if (Platform.isIOS) {
      final index = await methodChannel
          .invokeMethod<int>(MethodName.getIOSAudioSessionCategory);
      return index != null ? AudioSessionCategory.values[index] : null;
    }

    return null;
  }

  /// Get the default audio device on desktop.
  /// Use [deviceType] to specify the audio device type.
  static Future<AudioDevice?> getDefaultAudioDevice(
    AudioDeviceType deviceType,
  ) async {
    if (!isDesktopPlatform) {
      return null;
    }

    final jsonStr = await methodChannel.invokeMethod<String>(
      MethodName.getDefaultAudioDevice,
      {MethodArg.deviceType: deviceType.value},
    );

    if (jsonStr == null) {
      return null;
    }

    return AudioDevice.fromJson(jsonDecode(jsonStr));
  }

  /// Set the default audio device on desktop.
  /// Use [deviceType] to specify the audio device type.
  static Future<void> setDefaultAudioDevice({
    required String deviceId,
    required AudioDeviceType deviceType,
  }) async {
    if (!isDesktopPlatform) {
      return;
    }

    await methodChannel.invokeMethod(
      MethodName.setDefaultAudioDevice,
      {MethodArg.deviceId: deviceId, MethodArg.deviceType: deviceType.value},
    );
  }

  /// Get the audio output device list on desktop.
  /// Use [deviceType] to specify the audio device type.
  static Future<List<AudioDevice>> getAudioDeviceList(
    AudioDeviceType deviceType,
  ) async {
    if (!isDesktopPlatform) {
      return const [];
    }

    final jsonList = await methodChannel.invokeMethod<String>(
      MethodName.getAudioDeviceList,
      {MethodArg.deviceType: deviceType.value},
    );

    if (jsonList == null) {
      return const [];
    }

    final List<dynamic> devices = jsonDecode(jsonList);

    return devices.map((device) {
      return AudioDevice.fromJson(device);
    }).toList();
  }

  /// Set mono mode for the given audio output device.
  static Future<void> setOutputMonoMode({required String deviceId}) {
    if (!isDesktopPlatform) {
      return Future.value();
    }

    return methodChannel.invokeMethod(
      MethodName.setOutputMonoMode,
      {MethodArg.deviceId: deviceId},
    );
  }

  /// Listen for volume changes.
  /// Use [emitOnStart] to control whether volume value should be emitted
  /// immediately right after the listener is attached.
  /// Use [onChanged] to retrieve the updated volume level.
  /// Use [stream] to set the audio stream type on Android.
  /// Use [category] to set the audio session category type on iOS.
  static StreamSubscription<double> addListener(
    ValueChanged<double> onChanged, {
    AudioStream stream = _defaultAudioStream,
    AudioSessionCategory category = _defaultAudioSessionCategory,
    bool emitOnStart = true,
  }) {
    removeListener();

    final listener = eventChannel
        .receiveBroadcastStream({
          if (Platform.isAndroid) MethodArg.audioStream: stream.index,
          if (Platform.isIOS) MethodArg.audioSessionCategory: category.index,
          MethodArg.emitOnStart: emitOnStart,
        })
        .distinct()
        // ignore: unnecessary_lambdas
        .map((volume) => double.parse(volume))
        .listen(onChanged);

    _volumeListener = listener;
    return listener;
  }

  /// Remove the volume listener.
  static void removeListener() {
    _volumeListener?.cancel();
    _volumeListener = null;
  }

  /// Listener for default audio device changes.
  /// Use [emitOnStart] to control whether default output device should be emitted
  /// immediately right after the listener is attached.
  /// Use [deviceType] to specify the audio device type.
  static StreamSubscription<AudioDevice> addDefaultAudioDeviceListener(
    ValueChanged<AudioDevice> onChanged, {
    required AudioDeviceType deviceType,
    bool emitOnStart = true,
  }) {
    removeDefaultDeviceListener(deviceType);

    final listener = defaultAudioDeviceChannel
        .receiveBroadcastStream({
          MethodArg.emitOnStart: emitOnStart,
          MethodArg.deviceType: deviceType.value,
        })
        .map((device) => AudioDevice.fromJson(jsonDecode(device)))
        .listen(onChanged);

    _defaultInputDeviceListener = listener;
    return listener;
  }

  /// Remove the default audio device listener.
  static void removeDefaultDeviceListener([AudioDeviceType? deviceType]) {
    void removeInputDeviceListener() {
      _defaultInputDeviceListener?.cancel();
      _defaultInputDeviceListener = null;
    }

    void removeOutputDeviceListener() {
      _defaultOutputDeviceListener?.cancel();
      _defaultOutputDeviceListener = null;
    }

    switch (deviceType) {
      case AudioDeviceType.input:
        removeInputDeviceListener();
        break;
      case AudioDeviceType.output:
        removeOutputDeviceListener();
        break;
      default:
        removeInputDeviceListener();
        removeOutputDeviceListener();
        break;
    }
  }
}
