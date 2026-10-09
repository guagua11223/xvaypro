import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'logger.dart';
import 'prefs.dart';

class LocaleManager with ChangeNotifier {
  static final LocaleManager _instance = LocaleManager._internal();
  final Completer<void> _completer = Completer<void>();
  late Locale locale;

  // Private constructor
  LocaleManager._internal();

  // Singleton accessor
  factory LocaleManager() {
    return _instance;
  }

  Future<void> init() async {
    logger.d("starting: LocaleManager.init");
    update();
    _completer.complete(); // Signal that initialization is complete
    logger.d("finished: LocaleManager.init");
  }

  static const Locale chinese = Locale('zh', 'CN');

  Locale fromString(String localeString) {
    return locale = parse(localeString);
  }

  Locale parse(String localeString) {
    final localeParts = localeString.split("_");
    if (localeParts.length == 1) {
      return Locale(localeParts[0]); // e.g., "zh"
    }
    if (localeParts.length == 2) {
      return Locale(localeParts[0], localeParts[1]); // e.g., "zh_CN"
    }
    if (localeParts.length == 3) {
      return Locale.fromSubtags(
        languageCode: localeParts[0],
        scriptCode: localeParts[1],
        countryCode: localeParts[2],
      ); // e.g., "zh_Hans_CN"
    }
    logger.w("failed to parse locale $localeString");
    return chinese;
  }

  void update({bool notify = false}) {
    if (prefs.getBool('app.locale.followSystem')!) {
      final system = SchedulerBinding.instance.platformDispatcher.locale;
      locale = system.languageCode == 'zh' ? system : chinese;
    } else {
      locale = parse(prefs.getString('app.locale')!);
    }

    if (notify) {
      notifyListeners();
    }
  }
}

final localeManager = LocaleManager();
