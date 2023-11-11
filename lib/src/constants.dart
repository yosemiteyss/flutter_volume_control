abstract class MethodName {
  static const String getVolume = 'getVolume';
  static const String setVolume = 'setVolume';
  static const String raiseVolume = 'raiseVolume';
  static const String lowerVolume = 'lowerVolume';
  static const String setAndroidAudioStream = 'setAndroidAudioStream';
  static const String getAndroidAudioStream = 'getAndroidAudioStream';
  static const String setIOSAudioSessionCategory = 'setIOSAudioSessionCategory';
  static const String getIOSAudioSessionCategory = 'getIOSAudioSessionCategory';
  static const String getMute = 'getMute';
  static const String setMute = 'setMute';
  static const String toggleMute = 'toggleMute';
  static const String updateShowSystemUI = 'updateShowSystemUI';
  static const String getDefaultOutputDevice = 'getDefaultOutputDevice';
  static const String setDefaultOutputDevice = 'setDefaultOutputDevice';
  static const String getOutputDeviceList = 'getOutputDeviceList';
}

abstract class MethodArg {
  static const String volume = 'volume';
  static const String step = 'step';
  static const String showSystemUI = 'showSystemUI';
  static const String audioStream = 'audioStream';
  static const String audioSessionCategory = 'audioSessionCategory';
  static const String emitOnStart = 'emitOnStart';
  static const String isMuted = 'isMuted';
  static const String deviceId = 'deviceId';
}
