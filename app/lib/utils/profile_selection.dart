import 'package:flutter/material.dart';

import '../extensions/localization.dart';
import 'db.dart';
import 'prefs.dart';
import 'show_snack_bar_now.dart';
import 'vpn_manager.dart';

Future<void> selectProfileAndRestartIfNeeded({
  required BuildContext context,
  required ProfileData profile,
}) async {
  await prefs.setInt('app.selectedProfileId', profile.id);
  await prefs.setString('cache.app.selectedProfileName', profile.name);
  prefs.notifyListeners();

  if (!await vPNMan.getIsCoreActive()) {
    return;
  }
  if (context.mounted) {
    showSnackBarNow(context, Text(context.loc.reconnecting));
  }

  final res = await vPNMan.restartCore();
  if (!context.mounted) {
    return;
  }
  showSnackBarNow(
    context,
    Text(
      res
          ? context.loc.info_reconnected
          : context.loc.warning_failed_to_reconnect,
    ),
  );
}

Future<void> toggleVpnConnection(BuildContext context) async {
  final isCoreActive = await vPNMan.getIsCoreActive();

  Exception? err;
  try {
    if (isCoreActive) {
      await vPNMan.stopAll();
    } else {
      await vPNMan.startAll();
    }
  } on Exception catch (e) {
    err = e;
  } finally {
    if (err != null) {
      vPNMan.setisTogglingAll(false);
      if (context.mounted) {
        showSnackBarNow(context, Text("toggle: $err"));
      }
    }
  }
}
