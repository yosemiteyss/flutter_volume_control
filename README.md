# Flutter Volume Controller

A Flutter plugin to control system volume and listen for volume changes on different platforms.

[![pub package](https://img.shields.io/pub/v/flutter_volume_controller.svg)](https://pub.dev/packages/flutter_volume_controller)

## Features

- Control system and media volumes.
- Listen for volume changes.

## Platform Support

- ✅ Android
- ✅ iOS
- ✅ macOS
- ✅ Windows
- ✅ Linux

## Example

#### [Custom Volume Slider](example/lib/volume_slider_example.dart)

![volume-slider-example](screenshot/volume-slider-example.gif)

## Usage

#### Control System UI Visibility

- Set to `true` to display system volume slider when changing volume.
- This settings only works on Android and iOS.

```dart
FlutterVolumeController.showSystemUI = true;
```

#### Get Volume

```dart
final volume = await FlutterVolumeController.getVolume();
```

#### Set Volume

```dart
await FlutterVolumeController.setVolume(0.5);
```

#### Increase Volume

- On Android and Windows, when `step` is set to null, it will uses the default system stepping
  value.
- On iOS, macOS, Linux, if `step` is undefined, the default stepping value is set to `0.15`.

```dart
await FlutterVolumeController.raiseVolume(0.2);
await FlutterVolumeController.raiseVolume(null);
```

#### Decrease Volume

- On Android and Windows, when `step` is set to null, it will uses the default system stepping
  value.
- On iOS, macOS, Linux, if `step` is undefined, the default stepping value is set to `0.15`.

```dart
await FlutterVolumeController.lowerVolume(0.2);
await FlutterVolumeController.lowerVolume(null);
```

#### Check Mute

- On Android and iOS, we check if the current volume level is already dropped to zero.
- On macOS, Windows, Linux, we check if the mute switch is turned on.

```dart
final isMuted = await FlutterVolumeController.getMute();
```

#### Set Mute

- On Android and iOS, we either set the volume to zero or revert to the previous level.
- On macOS, Windows, Linux, we control the mute switch. Volume will be restored once it's unmuted.

```dart
await FlutterVolumeController.setMute(true);
await FlutterVolumeController.setMute(false);
```

#### Toggle Mute

```dart
await FlutterVolumeController.toggleMute();
```

#### Set Audio Stream on Android

- Adjusts to the audio stream whose volume should be changed by the hardware volume controls.
- Supported streams: `AudioStream.voiceCall`, `AudioStream.system`, `AudioStream.ring`
  , `AudioStream.music`, `AudioStream.alarm`.
- For more details,
  visit [AudioManager](https://developer.android.com/reference/android/media/AudioManager)

```dart
await FlutterVolumeController.setAndroidAudioStream(stream: AudioStream.system);
```

### Get Audio Stream on Android

- Get the current audio stream on Android.

```dart
final stream = await FlutterVolumeController.getAndroidAudioStream();
```

#### Set Audio Session Category on iOS

- Adjusts to a different set of audio behaviors.
- Supported categories: `AudioSessionCategory.ambient`, `AudioSessionCategory.multiRoute`
  , `AudioSessionCategory.playAndRecord`, `AudioSessionCategory.playback`
  , `AudioSessionCategory.record`, `AudioSessionCategory.soleAmbient`
- For more details,
  visit [AVAudioSession.Category](https://developer.apple.com/documentation/avfaudio/avaudiosession/category)

```dart
await FlutterVolumeController.setIOSAudioSessionCategory(category: AudioSessionCategory.playback);
```

#### Get Audio Session Category on iOS

- Get the current audio session category on iOS.

```dart
final category = await FlutterVolumeController.getIOSAudioSessionCategory();
```

#### Listen for Volume Changes

- Use `emitOnStart` to control whether volume level should be emitted immediately right after the
  listener is attached.

```dart
@override
void initState() {
  super.initState();
  FlutterVolumeController.addListener(
    (volume) {
      debugPrint('Volume changed: $volume');
    },
  );
}

@override
void dispose() {
  FlutterVolumeController.removeListener();
  super.dispose();
}
```

#### Listen for volume key action on Android

- Detect volume up and down button presses on Android.
- Before adding listener, make sure `MainActivity` is extending `FlutterVolumeControllerActivity`
  instead of `FlutterActivity`.

```kotlin
class MainActivity : FlutterVolumeControllerActivity()
```

```dart
@override
void initState() {
  super.initState();
  FlutterVolumeController.addAndroidKeyActionListener(
    (action) {
      debugPrint('Volume key action: $action');
    },
  );
}

@override
void dispose() {
  FlutterVolumeController.removeAndroidKeyActionListener();
  super.dispose();
}
```

## Notes

#### Fine-grained volume control

- Due to platform and device difference, it's normal that volume level could not be controlled
  precisely.
  For example, Android supports only 15 volume steps by default, the volume after being set would be
  a rounded off value.

## Reporting Bugs

- This package is under active development. If you find any bug, please create an issue on Github.

## Support
[!["Buy Me A Coffee"](https://www.buymeacoffee.com/assets/img/guidelines/download-assets-sm-1.svg)](https://buymeacoffee.com/yosemiteyss)