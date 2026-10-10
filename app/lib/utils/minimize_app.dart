import 'package:window_manager/window_manager.dart';

import 'method_channel.dart';
import 'runtime_platform.dart';

/// Minimize the app window (Windows) or move the task to background (Android).
Future<void> minimizeApp() async {
  if (RuntimePlatform.isWindows ||
      RuntimePlatform.isLinux ||
      RuntimePlatform.isMacOS) {
    await windowManager.minimize();
    return;
  }
  if (RuntimePlatform.isAndroid) {
    await mCMan.methodChannel.invokeMethod<void>('app.minimize');
  }
}
