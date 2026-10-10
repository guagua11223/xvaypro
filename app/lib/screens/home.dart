import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:path/path.dart' as p;
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../theme/lets_colors.dart';
import '../utils/global.dart';
import '../utils/permission_manager.dart';
import '../utils/prefs.dart';
import '../utils/runtime_platform.dart';
import '../utils/theme_manager.dart';
import '../utils/vpn_manager.dart';
import '../widgets/home_drawer_panel.dart';

import 'home/connect_home.dart';
import 'home/guide.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener, TrayListener {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _guideCompleted = prefs.getBool('app.guide.completed') ?? false;

  @override
  void initState() {
    trayManager.addListener(this);
    windowManager.addListener(this);
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await permMan.onHomeScreen(context);
    });
  }

  @override
  void dispose() {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    super.dispose();
  }

  void _openPage(Widget page) {
    if (_scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_guideCompleted) {
      return GuidePage(
        onFinished: () {
          setState(() {
            _guideCompleted = true;
          });
        },
      );
    }

    final isWide =
        !RuntimePlatform.isWindows && MediaQuery.sizeOf(context).width >= 900;

    if (isWide) {
      return Scaffold(
        backgroundColor: LetsColors.of(context).page,
        body: Row(
          children: [
            SizedBox(
              width: 320,
              child: Material(
                elevation: 4,
                child: HomeDrawerPanel(
                  showBackButton: false,
                  onNavigate: _openPage,
                ),
              ),
            ),
            const Expanded(
              child: ConnectHome(showMenuButton: false),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: LetsColors.of(context).page,
      drawer: Drawer(
        width: math.min(360, MediaQuery.sizeOf(context).width * 0.86),
        backgroundColor: LetsColors.of(context).surface,
        child: HomeDrawerPanel(onNavigate: _openPage),
      ),
      body: ConnectHome(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
      ),
    );
  }

  static final pendingInstallerExitFlagFile = File(
    p.join(
      global.applicationSupportDirectory.path,
      "pending_installer_exit.flag",
    ),
  );

  @override
  void onWindowClose() async {
    if (RuntimePlatform.isWindows &&
        await pendingInstallerExitFlagFile.exists()) {
      await pendingInstallerExitFlagFile.delete();
      await vPNMan.stopAll();
      exit(0);
    }
    windowManager.hide();
  }

  /// only on Windows, macOS
  @override
  void onTrayIconMouseDown() async {
    windowManager.show();
    windowManager.setSkipTaskbar(false);
  }

  /// only on Windows, macOS
  @override
  void onTrayIconRightMouseDown() async {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        windowManager.show();
      case 'hide':
        windowManager.hide();
      case 'exit':
        await vPNMan.stopAll();
        exit(0);
      case 'toggle_all':
        final shouldEnable = !menuItem.checked!;
        menuItem.checked = shouldEnable;
        if (shouldEnable) {
          vPNMan.startAll();
        } else {
          vPNMan.stopAll();
        }
      case 'toggle_tun':
        final shouldEnable = !menuItem.checked!;
        menuItem.checked = shouldEnable;
        await prefs.setBool("tun", shouldEnable);
        prefs.notifyListeners();
        if (await vPNMan.getIsCoreActive()) {
          if (shouldEnable) {
            await vPNMan.startTun();
          } else {
            await vPNMan.stopTun();
          }
        }
      case 'toggle_system_proxy':
        final shouldEnable = !menuItem.checked!;
        menuItem.checked = shouldEnable;
        await prefs.setBool("systemProxy", shouldEnable);
        prefs.notifyListeners();
        if (await vPNMan.getIsCoreActive()) {
          if (shouldEnable) {
            await vPNMan.startSystemProxy();
          } else {
            await vPNMan.stopSystemProxy();
          }
        }
    }
  }

  @override
  void onWindowFocus() {
    setState(() {});
  }

  @override
  void onWindowResized() async {
    final size = await windowManager.getSize();
    prefs.setDouble("app.window.size.width", size.width);
    prefs.setDouble("app.window.size.height", size.height);
  }

  @override
  void onWindowMaximize() async {
    prefs.setBool("app.window.isMaximized", true);
  }

  @override
  void onWindowUnmaximize() async {
    prefs.setBool("app.window.isMaximized", false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    themeManager.update().then((_) {
      if (RuntimePlatform.isWindows || RuntimePlatform.isMacOS) {
        var isDark = themeManager.isDark;
        Window.setEffect(
          effect: RuntimePlatform.isWindows
              ? WindowEffect.solid
              : WindowEffect.disabled,
          dark: isDark,
        );
      }
    });
  }
}
