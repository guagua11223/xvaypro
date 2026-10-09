import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_id.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_th.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('hi'),
    Locale('id'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('th'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
  ];

  /// No description provided for @a_url_that_returns_204.
  ///
  /// In en, this message translates to:
  /// **'A url that returns 204'**
  String get a_url_that_returns_204;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @add_asset.
  ///
  /// In en, this message translates to:
  /// **'Add asset'**
  String get add_asset;

  /// No description provided for @add_core.
  ///
  /// In en, this message translates to:
  /// **'Add core'**
  String get add_core;

  /// No description provided for @add_core_type.
  ///
  /// In en, this message translates to:
  /// **'Add core type'**
  String get add_core_type;

  /// No description provided for @add_profile.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get add_profile;

  /// No description provided for @add_profile_group.
  ///
  /// In en, this message translates to:
  /// **'Add profile group'**
  String get add_profile_group;

  /// No description provided for @administrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get administrator;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @all_apps_are_proxied_if_disabled.
  ///
  /// In en, this message translates to:
  /// **'All apps are proxied if disabled'**
  String get all_apps_are_proxied_if_disabled;

  /// No description provided for @all_apps_in_allowed_list_will_be_proxied.
  ///
  /// In en, this message translates to:
  /// **'All apps in allowed list will be proxied'**
  String get all_apps_in_allowed_list_will_be_proxied;

  /// No description provided for @all_apps_not_in_disallowed_list_will_be_proxied.
  ///
  /// In en, this message translates to:
  /// **'All apps not in disallowed list will be proxied'**
  String get all_apps_not_in_disallowed_list_will_be_proxied;

  /// No description provided for @all_ipv4_defined_in_dns_servers_will_not_be_proxied.
  ///
  /// In en, this message translates to:
  /// **'All IPv4 defined in dns.servers will not be proxied'**
  String get all_ipv4_defined_in_dns_servers_will_not_be_proxied;

  /// No description provided for @allowed_all_apps_in_allowed_list_will_be_proxied.
  ///
  /// In en, this message translates to:
  /// **'Allowed: all apps in allowed list will be proxied'**
  String get allowed_all_apps_in_allowed_list_will_be_proxied;

  /// No description provided for @allowed_applications.
  ///
  /// In en, this message translates to:
  /// **'Allowed applications'**
  String get allowed_applications;

  /// No description provided for @api_config.
  ///
  /// In en, this message translates to:
  /// **'Api config'**
  String get api_config;

  /// No description provided for @api_port.
  ///
  /// In en, this message translates to:
  /// **'Api port'**
  String get api_port;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'App name'**
  String get app_name;

  /// No description provided for @append_a_fake_dns_server_so_unresolved_domains_will_be_resolved_by_proxy_server_this_will_disable_dns_fallback_and_may_contaminate_the_local_dns_cache.
  ///
  /// In en, this message translates to:
  /// **'Append a FakeDNS server so unresolved domains will be resolved by proxy server - this will disable DNS fallback, and may contaminate the local DNS cache'**
  String
  get append_a_fake_dns_server_so_unresolved_domains_will_be_resolved_by_proxy_server_this_will_disable_dns_fallback_and_may_contaminate_the_local_dns_cache;

  /// No description provided for @args.
  ///
  /// In en, this message translates to:
  /// **'Args'**
  String get args;

  /// No description provided for @asset_path.
  ///
  /// In en, this message translates to:
  /// **'Asset path'**
  String get asset_path;

  /// No description provided for @asset_type.
  ///
  /// In en, this message translates to:
  /// **'Asset type'**
  String get asset_type;

  /// No description provided for @assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get assets;

  /// No description provided for @assets_remote_auto_update_etc_.
  ///
  /// In en, this message translates to:
  /// **'Assets remote auto update, etc.'**
  String get assets_remote_auto_update_etc_;

  /// No description provided for @auto_change_brightness_based_on_system_settings.
  ///
  /// In en, this message translates to:
  /// **'Auto change brightness based on system settings'**
  String get auto_change_brightness_based_on_system_settings;

  /// No description provided for @auto_change_language_based_on_system_settings.
  ///
  /// In en, this message translates to:
  /// **'Auto change language based on system settings'**
  String get auto_change_language_based_on_system_settings;

  /// No description provided for @auto_connect_at_app_launch.
  ///
  /// In en, this message translates to:
  /// **'Auto connect at app launch'**
  String get auto_connect_at_app_launch;

  /// No description provided for @auto_connect_at_device_boot.
  ///
  /// In en, this message translates to:
  /// **'Auto connect at device boot'**
  String get auto_connect_at_device_boot;

  /// No description provided for @auto_connect_selected_profile_at_app_launch.
  ///
  /// In en, this message translates to:
  /// **'Auto connect selected profile at app launch'**
  String get auto_connect_selected_profile_at_app_launch;

  /// No description provided for @auto_connect_selected_profile_at_device_boot.
  ///
  /// In en, this message translates to:
  /// **'Auto connect selected profile at device boot'**
  String get auto_connect_selected_profile_at_device_boot;

  /// No description provided for @auto_download_installer_and_update_on_next_app_launch.
  ///
  /// In en, this message translates to:
  /// **'Auto download installer and update on next app launch'**
  String get auto_download_installer_and_update_on_next_app_launch;

  /// No description provided for @auto_launch.
  ///
  /// In en, this message translates to:
  /// **'Auto launch'**
  String get auto_launch;

  /// No description provided for @auto_launch_at_login.
  ///
  /// In en, this message translates to:
  /// **'Auto launch at login'**
  String get auto_launch_at_login;

  /// No description provided for @auto_startup_tray_icon_etc_.
  ///
  /// In en, this message translates to:
  /// **'Auto startup, tray icon, etc.'**
  String get auto_startup_tray_icon_etc_;

  /// No description provided for @auto_update.
  ///
  /// In en, this message translates to:
  /// **'Auto update'**
  String get auto_update;

  /// No description provided for @auto_update_interval_seconds_0_to_disable.
  ///
  /// In en, this message translates to:
  /// **'Auto update interval (seconds), 0 to disable'**
  String get auto_update_interval_seconds_0_to_disable;

  /// No description provided for @bind_all_outbounds_to_ip_address_useful_when_using_with_some_tun_tools.
  ///
  /// In en, this message translates to:
  /// **'Bind all outbounds to ip address, useful when using with some Tun tools'**
  String
  get bind_all_outbounds_to_ip_address_useful_when_using_with_some_tun_tools;

  /// No description provided for @binding_interface.
  ///
  /// In en, this message translates to:
  /// **'Binding interface'**
  String get binding_interface;

  /// No description provided for @binding_ip.
  ///
  /// In en, this message translates to:
  /// **'Binding ip'**
  String get binding_ip;

  /// No description provided for @black_dark.
  ///
  /// In en, this message translates to:
  /// **'Black dark'**
  String get black_dark;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @check_update.
  ///
  /// In en, this message translates to:
  /// **'Check update'**
  String get check_update;

  /// No description provided for @close_to_tray.
  ///
  /// In en, this message translates to:
  /// **'Close to tray'**
  String get close_to_tray;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @connectivity.
  ///
  /// In en, this message translates to:
  /// **'Connectivity'**
  String get connectivity;

  /// No description provided for @connectivity_basic_settings.
  ///
  /// In en, this message translates to:
  /// **'Connectivity basic settings'**
  String get connectivity_basic_settings;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @core.
  ///
  /// In en, this message translates to:
  /// **'Core'**
  String get core;

  /// No description provided for @core_config.
  ///
  /// In en, this message translates to:
  /// **'Core config'**
  String get core_config;

  /// No description provided for @core_config_format.
  ///
  /// In en, this message translates to:
  /// **'Core config format'**
  String get core_config_format;

  /// No description provided for @core_executable.
  ///
  /// In en, this message translates to:
  /// **'Core executable'**
  String get core_executable;

  /// No description provided for @core_path_does_not_exist.
  ///
  /// In en, this message translates to:
  /// **'Core path does not exist'**
  String get core_path_does_not_exist;

  /// No description provided for @core_type.
  ///
  /// In en, this message translates to:
  /// **'Core type'**
  String get core_type;

  /// No description provided for @cores.
  ///
  /// In en, this message translates to:
  /// **'Cores'**
  String get cores;

  /// No description provided for @dark_theme.
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get dark_theme;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @default_.
  ///
  /// In en, this message translates to:
  /// **'default'**
  String get default_;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get direct;

  /// No description provided for @direct_speed.
  ///
  /// In en, this message translates to:
  /// **'Direct speed'**
  String get direct_speed;

  /// No description provided for @disable_to_show_all_toggles_inside_a_dashboard_pane_instead.
  ///
  /// In en, this message translates to:
  /// **'Disable to show all toggles inside a dashboard pane instead'**
  String get disable_to_show_all_toggles_inside_a_dashboard_pane_instead;

  /// No description provided for @disallowed_all_apps_not_in_disallowed_list_will_be_proxied.
  ///
  /// In en, this message translates to:
  /// **'Disallowed: all apps not in disallowed list will be proxied'**
  String get disallowed_all_apps_not_in_disallowed_list_will_be_proxied;

  /// No description provided for @disallowed_applications.
  ///
  /// In en, this message translates to:
  /// **'Disallowed applications'**
  String get disallowed_applications;

  /// No description provided for @dns_config.
  ///
  /// In en, this message translates to:
  /// **'DNS config'**
  String get dns_config;

  /// No description provided for @dns_ipv4.
  ///
  /// In en, this message translates to:
  /// **'DNS IPv4'**
  String get dns_ipv4;

  /// No description provided for @dns_ipv6.
  ///
  /// In en, this message translates to:
  /// **'DNS IPv6'**
  String get dns_ipv6;

  /// No description provided for @dock_to_tray_instead_when_app_window_is_closed.
  ///
  /// In en, this message translates to:
  /// **'Dock to tray instead when app window is closed'**
  String get dock_to_tray_instead_when_app_window_is_closed;

  /// No description provided for @e_g_c_path_to_v2ray_exe.
  ///
  /// In en, this message translates to:
  /// **'e.g. C:\\path\\to\\v2ray.exe'**
  String get e_g_c_path_to_v2ray_exe;

  /// No description provided for @e_g_github_v2fly_v2ray_core_v2ray_windows_64_zip_v2ray_exe.
  ///
  /// In en, this message translates to:
  /// **'e.g. github://v2fly/v2ray-core/v2ray-windows-64.zip/v2ray.exe'**
  String get e_g_github_v2fly_v2ray_core_v2ray_windows_64_zip_v2ray_exe;

  /// No description provided for @e_g_path_to_v2ray.
  ///
  /// In en, this message translates to:
  /// **'e.g. /path/to/v2ray'**
  String get e_g_path_to_v2ray;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @edit_asset.
  ///
  /// In en, this message translates to:
  /// **'Edit asset'**
  String get edit_asset;

  /// No description provided for @edit_config.
  ///
  /// In en, this message translates to:
  /// **'Edit config'**
  String get edit_config;

  /// No description provided for @edit_core.
  ///
  /// In en, this message translates to:
  /// **'Edit core'**
  String get edit_core;

  /// No description provided for @edit_core_type.
  ///
  /// In en, this message translates to:
  /// **'Edit core type'**
  String get edit_core_type;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get edit_profile;

  /// No description provided for @edit_profile_group.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile Group'**
  String get edit_profile_group;

  /// No description provided for @either_to_match_predefined_profile_or_for_profile_injection.
  ///
  /// In en, this message translates to:
  /// **'Either to match predefined profile or for profile injection'**
  String get either_to_match_predefined_profile_or_for_profile_injection;

  /// No description provided for @embedded.
  ///
  /// In en, this message translates to:
  /// **'Embedded'**
  String get embedded;

  /// No description provided for @enable_ipv4.
  ///
  /// In en, this message translates to:
  /// **'enable IPv4'**
  String get enable_ipv4;

  /// No description provided for @enable_ipv6.
  ///
  /// In en, this message translates to:
  /// **'enable IPv6'**
  String get enable_ipv6;

  /// No description provided for @enable_system_proxy.
  ///
  /// In en, this message translates to:
  /// **'Enable system proxy'**
  String get enable_system_proxy;

  /// No description provided for @enable_tun.
  ///
  /// In en, this message translates to:
  /// **'Enable Tun'**
  String get enable_tun;

  /// No description provided for @enable_tun2socks.
  ///
  /// In en, this message translates to:
  /// **'Enable Tun2socks'**
  String get enable_tun2socks;

  /// No description provided for @enable_tun2socks_so_a_socks_proxy_works_like_a_vpn.
  ///
  /// In en, this message translates to:
  /// **'Enable Tun2socks so a socks proxy works like a VPN'**
  String get enable_tun2socks_so_a_socks_proxy_works_like_a_vpn;

  /// No description provided for @enable_tun2socks_so_a_socks_proxy_works_like_a_vpn_requires_elevation_.
  ///
  /// In en, this message translates to:
  /// **'Enable Tun2socks so a socks proxy works like a VPN\nRequires elevation'**
  String
  get enable_tun2socks_so_a_socks_proxy_works_like_a_vpn_requires_elevation_;

  /// No description provided for @enable_tun_via_platform_api_.
  ///
  /// In en, this message translates to:
  /// **'Enable tun (via platform api)'**
  String get enable_tun_via_platform_api_;

  /// No description provided for @enable_tun_via_root_.
  ///
  /// In en, this message translates to:
  /// **'Enable tun (via root)'**
  String get enable_tun_via_root_;

  /// No description provided for @envs.
  ///
  /// In en, this message translates to:
  /// **'Envs'**
  String get envs;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @failed_to_fetch_url.
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch: {url}'**
  String failed_to_fetch_url(String url);

  /// No description provided for @first_install_time.
  ///
  /// In en, this message translates to:
  /// **'First install time'**
  String get first_install_time;

  /// No description provided for @follow_system_brightness.
  ///
  /// In en, this message translates to:
  /// **'Follow system brightness'**
  String get follow_system_brightness;

  /// No description provided for @follow_system_locale.
  ///
  /// In en, this message translates to:
  /// **'Follow system locale'**
  String get follow_system_locale;

  /// No description provided for @foreground.
  ///
  /// In en, this message translates to:
  /// **'Foreground'**
  String get foreground;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @general_settings.
  ///
  /// In en, this message translates to:
  /// **'General settings'**
  String get general_settings;

  /// No description provided for @generated_assets.
  ///
  /// In en, this message translates to:
  /// **'Generated assets'**
  String get generated_assets;

  /// No description provided for @github_token.
  ///
  /// In en, this message translates to:
  /// **'GitHub token'**
  String get github_token;

  /// No description provided for @github_token_increase_rate_limits.
  ///
  /// In en, this message translates to:
  /// **'GitHub token increase rate limits'**
  String get github_token_increase_rate_limits;

  /// No description provided for @go_coroutines.
  ///
  /// In en, this message translates to:
  /// **'Go coroutines'**
  String get go_coroutines;

  /// No description provided for @http_port.
  ///
  /// In en, this message translates to:
  /// **'HTTP port'**
  String get http_port;

  /// No description provided for @inbound_config.
  ///
  /// In en, this message translates to:
  /// **'Inbound config'**
  String get inbound_config;

  /// No description provided for @info_reconnected.
  ///
  /// In en, this message translates to:
  /// **'INFO: Reconnected'**
  String get info_reconnected;

  /// No description provided for @inject_api.
  ///
  /// In en, this message translates to:
  /// **'Inject api'**
  String get inject_api;

  /// No description provided for @inject_configuration_into_v2ray_xray_profile.
  ///
  /// In en, this message translates to:
  /// **'Inject configuration into v2ray/xray profile'**
  String get inject_configuration_into_v2ray_xray_profile;

  /// No description provided for @inject_fake_dns.
  ///
  /// In en, this message translates to:
  /// **'Inject FakeDNS'**
  String get inject_fake_dns;

  /// No description provided for @inject_http_inbound.
  ///
  /// In en, this message translates to:
  /// **'Inject http inbound'**
  String get inject_http_inbound;

  /// No description provided for @inject_local_dns.
  ///
  /// In en, this message translates to:
  /// **'Inject local DNS'**
  String get inject_local_dns;

  /// No description provided for @inject_log.
  ///
  /// In en, this message translates to:
  /// **'Inject Log'**
  String get inject_log;

  /// No description provided for @inject_rule_to_exclude_core_dns.
  ///
  /// In en, this message translates to:
  /// **'Inject rule to exclude core DNS'**
  String get inject_rule_to_exclude_core_dns;

  /// No description provided for @inject_rule_to_exclude_core_path.
  ///
  /// In en, this message translates to:
  /// **'Inject rule to exclude core path'**
  String get inject_rule_to_exclude_core_path;

  /// No description provided for @inject_send_through.
  ///
  /// In en, this message translates to:
  /// **'Inject sendThrough'**
  String get inject_send_through;

  /// No description provided for @inject_socks_inbound.
  ///
  /// In en, this message translates to:
  /// **'Inject socks inbound'**
  String get inject_socks_inbound;

  /// No description provided for @inject_socks_outbound.
  ///
  /// In en, this message translates to:
  /// **'Inject socks outbound'**
  String get inject_socks_outbound;

  /// No description provided for @install_now.
  ///
  /// In en, this message translates to:
  /// **'Install now'**
  String get install_now;

  /// No description provided for @installed_apps.
  ///
  /// In en, this message translates to:
  /// **'Installed apps'**
  String get installed_apps;

  /// No description provided for @ip_not_found_for_binding_interface_binding_interface.
  ///
  /// In en, this message translates to:
  /// **'IP not found for binding interface: {bindingInterface}'**
  String ip_not_found_for_binding_interface_binding_interface(
    String bindingInterface,
  );

  /// No description provided for @ipv4.
  ///
  /// In en, this message translates to:
  /// **'IPv4'**
  String get ipv4;

  /// No description provided for @ipv6.
  ///
  /// In en, this message translates to:
  /// **'IPv6'**
  String get ipv6;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @language_settings.
  ///
  /// In en, this message translates to:
  /// **'Language settings'**
  String get language_settings;

  /// No description provided for @last_checked_datetime.
  ///
  /// In en, this message translates to:
  /// **'Last checked: {datetime}'**
  String last_checked_datetime(String datetime);

  /// No description provided for @last_update_time.
  ///
  /// In en, this message translates to:
  /// **'Last update time'**
  String get last_update_time;

  /// No description provided for @launch_settings.
  ///
  /// In en, this message translates to:
  /// **'Launch settings'**
  String get launch_settings;

  /// No description provided for @live_objects.
  ///
  /// In en, this message translates to:
  /// **'Live obj.'**
  String get live_objects;

  /// No description provided for @local_directory.
  ///
  /// In en, this message translates to:
  /// **'Local directory'**
  String get local_directory;

  /// No description provided for @local_profile_group.
  ///
  /// In en, this message translates to:
  /// **'Local profile group'**
  String get local_profile_group;

  /// No description provided for @log_config.
  ///
  /// In en, this message translates to:
  /// **'Log config'**
  String get log_config;

  /// No description provided for @log_config_override.
  ///
  /// In en, this message translates to:
  /// **'Log config override'**
  String get log_config_override;

  /// No description provided for @log_level.
  ///
  /// In en, this message translates to:
  /// **'Log Level'**
  String get log_level;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @manually_created_profiles.
  ///
  /// In en, this message translates to:
  /// **'Manually created profiles'**
  String get manually_created_profiles;

  /// No description provided for @memory.
  ///
  /// In en, this message translates to:
  /// **'Mem.'**
  String get memory;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @necessary_for_dashboard_infomation.
  ///
  /// In en, this message translates to:
  /// **'Necessary for dashboard infomation'**
  String get necessary_for_dashboard_infomation;

  /// No description provided for @no_profile_yet_create_one_first.
  ///
  /// In en, this message translates to:
  /// **'No profile yet, create one first'**
  String get no_profile_yet_create_one_first;

  /// No description provided for @notification.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @notification_permission_is_required_for_quick_tiles_to_work_properly.
  ///
  /// In en, this message translates to:
  /// **'Notification permission is required for quick tiles to work properly'**
  String
  get notification_permission_is_required_for_quick_tiles_to_work_properly;

  /// No description provided for @open_settings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get open_settings;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @outbound_config_additional_socks_outbound.
  ///
  /// In en, this message translates to:
  /// **'Outbound config: additional socks outbound'**
  String get outbound_config_additional_socks_outbound;

  /// No description provided for @outbound_config_send_through.
  ///
  /// In en, this message translates to:
  /// **'Outbound config: sendThrough'**
  String get outbound_config_send_through;

  /// No description provided for @override_log_config.
  ///
  /// In en, this message translates to:
  /// **'Override log config'**
  String get override_log_config;

  /// No description provided for @path_of_core_exectuable_assets_etc_.
  ///
  /// In en, this message translates to:
  /// **'Path of core exectuable, assets, etc.'**
  String get path_of_core_exectuable_assets_etc_;

  /// No description provided for @pending_install_tag_name.
  ///
  /// In en, this message translates to:
  /// **'Pending install: {tagName}'**
  String pending_install_tag_name(String tagName);

  /// No description provided for @per_app_proxy.
  ///
  /// In en, this message translates to:
  /// **'Per-app proxy'**
  String get per_app_proxy;

  /// No description provided for @per_app_proxy_mode.
  ///
  /// In en, this message translates to:
  /// **'Per-app proxy mode'**
  String get per_app_proxy_mode;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @permission_required.
  ///
  /// In en, this message translates to:
  /// **'Permission Required'**
  String get permission_required;

  /// No description provided for @ping_http_address.
  ///
  /// In en, this message translates to:
  /// **'Ping (HTTP) address'**
  String get ping_http_address;

  /// No description provided for @ping_maximum_concurrency.
  ///
  /// In en, this message translates to:
  /// **'Ping maximum concurrency'**
  String get ping_maximum_concurrency;

  /// No description provided for @please_select_a_core_type_name_core.
  ///
  /// In en, this message translates to:
  /// **'Please select a {coreTypeName} core'**
  String please_select_a_core_type_name_core(String coreTypeName);

  /// No description provided for @please_select_a_profile.
  ///
  /// In en, this message translates to:
  /// **'Please select a profile'**
  String get please_select_a_profile;

  /// No description provided for @please_specify_v2ray_core_executable_path.
  ///
  /// In en, this message translates to:
  /// **'Please specify v2ray-core executable path'**
  String get please_specify_v2ray_core_executable_path;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get port;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @profile_group.
  ///
  /// In en, this message translates to:
  /// **'Profile group'**
  String get profile_group;

  /// No description provided for @profile_override.
  ///
  /// In en, this message translates to:
  /// **'Profile override'**
  String get profile_override;

  /// No description provided for @profile_type.
  ///
  /// In en, this message translates to:
  /// **'Profile type'**
  String get profile_type;

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @protocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get protocol;

  /// No description provided for @provided_by_os_not_all_apps_respect_this_setting.
  ///
  /// In en, this message translates to:
  /// **'Provided by OS, not all apps respect this setting'**
  String get provided_by_os_not_all_apps_respect_this_setting;

  /// No description provided for @proxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get proxy;

  /// No description provided for @proxy_speed.
  ///
  /// In en, this message translates to:
  /// **'Proxy speed'**
  String get proxy_speed;

  /// No description provided for @reconnected.
  ///
  /// In en, this message translates to:
  /// **'Reconnected'**
  String get reconnected;

  /// No description provided for @reconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting'**
  String get reconnecting;

  /// No description provided for @replace_local_dns_with_explicit_ip_and_bind_proxy_server_domain_names_to_it_useful_when_using_tun.
  ///
  /// In en, this message translates to:
  /// **'Replace local DNS with explicit IP and bind proxy server domain names to it, useful when using Tun'**
  String
  get replace_local_dns_with_explicit_ip_and_bind_proxy_server_domain_names_to_it_useful_when_using_tun;

  /// No description provided for @routing_rule_additional_rules.
  ///
  /// In en, this message translates to:
  /// **'Routing rule: additional rules'**
  String get routing_rule_additional_rules;

  /// No description provided for @routing_rule_additionally_exclude_core_path.
  ///
  /// In en, this message translates to:
  /// **'Routing rule: additionally exclude core path'**
  String get routing_rule_additionally_exclude_core_path;

  /// No description provided for @run_as_elevated_user.
  ///
  /// In en, this message translates to:
  /// **'Run as {elevatedUser}'**
  String run_as_elevated_user(String elevatedUser);

  /// No description provided for @runs_the_service_in_foreground_less_likely_be_killed_by_system_a_notification_must_show.
  ///
  /// In en, this message translates to:
  /// **'Runs the service in foreground (less likely be killed by system). A notification must show'**
  String
  get runs_the_service_in_foreground_less_likely_be_killed_by_system_a_notification_must_show;

  /// No description provided for @save_and_update.
  ///
  /// In en, this message translates to:
  /// **'Save and update'**
  String get save_and_update;

  /// No description provided for @see_settings_connectivity.
  ///
  /// In en, this message translates to:
  /// **'See `Settings` -> `Connectivity'**
  String get see_settings_connectivity;

  /// No description provided for @selected_profile.
  ///
  /// In en, this message translates to:
  /// **'Selected profile'**
  String get selected_profile;

  /// No description provided for @send_through_binding_stratagy.
  ///
  /// In en, this message translates to:
  /// **'SendThrough binding stratagy'**
  String get send_through_binding_stratagy;

  /// No description provided for @send_through_ip_binding_stratagy.
  ///
  /// In en, this message translates to:
  /// **'SendThrough ip binding stratagy'**
  String get send_through_ip_binding_stratagy;

  /// No description provided for @server_address.
  ///
  /// In en, this message translates to:
  /// **'Server address'**
  String get server_address;

  /// No description provided for @set_to_0_to_disable.
  ///
  /// In en, this message translates to:
  /// **'Set to 0 to disable'**
  String get set_to_0_to_disable;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @show_dashboard_floating_button.
  ///
  /// In en, this message translates to:
  /// **'Show dashboard floating button'**
  String get show_dashboard_floating_button;

  /// No description provided for @show_system_apps.
  ///
  /// In en, this message translates to:
  /// **'Show system apps'**
  String get show_system_apps;

  /// No description provided for @sing_box_path_is_null.
  ///
  /// In en, this message translates to:
  /// **'sing-box path is null'**
  String get sing_box_path_is_null;

  /// No description provided for @socks_and_http.
  ///
  /// In en, this message translates to:
  /// **'Socks and HTTP'**
  String get socks_and_http;

  /// No description provided for @socks_password.
  ///
  /// In en, this message translates to:
  /// **'Socks password'**
  String get socks_password;

  /// No description provided for @socks_port.
  ///
  /// In en, this message translates to:
  /// **'Socks port'**
  String get socks_port;

  /// No description provided for @socks_user_name.
  ///
  /// In en, this message translates to:
  /// **'Socks user name'**
  String get socks_user_name;

  /// No description provided for @sort_by.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sort_by;

  /// No description provided for @speed_graph.
  ///
  /// In en, this message translates to:
  /// **'Speed graph'**
  String get speed_graph;

  /// No description provided for @standalone.
  ///
  /// In en, this message translates to:
  /// **'Standalone'**
  String get standalone;

  /// No description provided for @storage_permission_is_required_for_cores_to_load_assets_.
  ///
  /// In en, this message translates to:
  /// **'Storage permission is required for cores to load assets.'**
  String get storage_permission_is_required_for_cores_to_load_assets_;

  /// No description provided for @system_proxy.
  ///
  /// In en, this message translates to:
  /// **'System proxy'**
  String get system_proxy;

  /// No description provided for @theme_settings.
  ///
  /// In en, this message translates to:
  /// **'Theme settings'**
  String get theme_settings;

  /// No description provided for @toggles.
  ///
  /// In en, this message translates to:
  /// **'Toggles'**
  String get toggles;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @total_speed.
  ///
  /// In en, this message translates to:
  /// **'Total speed'**
  String get total_speed;

  /// No description provided for @traffic.
  ///
  /// In en, this message translates to:
  /// **'Traffic'**
  String get traffic;

  /// No description provided for @tun2socks_settings.
  ///
  /// In en, this message translates to:
  /// **'Tun2socks settings'**
  String get tun2socks_settings;

  /// No description provided for @tun_needs_additionally_a_sing_box_core.
  ///
  /// In en, this message translates to:
  /// **'Tun needs (additionally) a sing-box core'**
  String get tun_needs_additionally_a_sing_box_core;

  /// No description provided for @tun_settings.
  ///
  /// In en, this message translates to:
  /// **'Tun settings'**
  String get tun_settings;

  /// No description provided for @tun_stack.
  ///
  /// In en, this message translates to:
  /// **'Tun stack'**
  String get tun_stack;

  /// No description provided for @tun_via_platform_api_.
  ///
  /// In en, this message translates to:
  /// **'Tun (via platform api)'**
  String get tun_via_platform_api_;

  /// No description provided for @tun_via_root_.
  ///
  /// In en, this message translates to:
  /// **'Tun (via root)'**
  String get tun_via_root_;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @typically_required_by_tun.
  ///
  /// In en, this message translates to:
  /// **'Typically required by Tun'**
  String get typically_required_by_tun;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'Uptime'**
  String get uptime;

  /// No description provided for @url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get url;

  /// No description provided for @use_black_background_in_dark_theme.
  ///
  /// In en, this message translates to:
  /// **'Use black background in dark theme'**
  String get use_black_background_in_dark_theme;

  /// No description provided for @use_dark_theme.
  ///
  /// In en, this message translates to:
  /// **'Use dark theme'**
  String get use_dark_theme;

  /// No description provided for @user_data.
  ///
  /// In en, this message translates to:
  /// **'User data'**
  String get user_data;

  /// No description provided for @view_app_log.
  ///
  /// In en, this message translates to:
  /// **'View app log'**
  String get view_app_log;

  /// No description provided for @view_core_log.
  ///
  /// In en, this message translates to:
  /// **'View core log'**
  String get view_core_log;

  /// No description provided for @view_tun2socks_log.
  ///
  /// In en, this message translates to:
  /// **'View Tun2socks log'**
  String get view_tun2socks_log;

  /// No description provided for @vitual_network_adaptor.
  ///
  /// In en, this message translates to:
  /// **'Vitual network adaptor'**
  String get vitual_network_adaptor;

  /// No description provided for @warning_failed_due_to_unable_to_update_launch_at_login.
  ///
  /// In en, this message translates to:
  /// **'WARNING: failed due to unable to update launchAtLogin'**
  String get warning_failed_due_to_unable_to_update_launch_at_login;

  /// No description provided for @warning_failed_to_reconnect.
  ///
  /// In en, this message translates to:
  /// **'WARNING: Failed to reconnect'**
  String get warning_failed_to_reconnect;

  /// No description provided for @warning_invalid_asset.
  ///
  /// In en, this message translates to:
  /// **'WARNING: invalid asset'**
  String get warning_invalid_asset;

  /// No description provided for @warning_invalid_url.
  ///
  /// In en, this message translates to:
  /// **'WARNING: invalid URL'**
  String get warning_invalid_url;

  /// No description provided for @warning_no_core_selected_.
  ///
  /// In en, this message translates to:
  /// **'WARNING: no core selected!'**
  String get warning_no_core_selected_;

  /// No description provided for @warning_you_need_to_be_elevated_user_to_enable_tun.
  ///
  /// In en, this message translates to:
  /// **'WARNING: you need to be {elevatedUser} to enable Tun'**
  String warning_you_need_to_be_elevated_user_to_enable_tun(
    String elevatedUser,
  );

  /// No description provided for @warning_you_need_to_be_elevated_user_to_modify_this_setting.
  ///
  /// In en, this message translates to:
  /// **'WARNING: you need to be {elevatedUser} to modify this setting'**
  String warning_you_need_to_be_elevated_user_to_modify_this_setting(
    String elevatedUser,
  );

  /// No description provided for @working_dir.
  ///
  /// In en, this message translates to:
  /// **'Working dir'**
  String get working_dir;

  /// No description provided for @works_fine_on_windows_will_fail_on_other_systems_with_short_lived_packets_like_dns_.
  ///
  /// In en, this message translates to:
  /// **'Works fine on Windows, will fail on other systems with short-lived packets (like DNS)'**
  String
  get works_fine_on_windows_will_fail_on_other_systems_with_short_lived_packets_like_dns_;

  /// No description provided for @you_may_want_to_check_settings_profile_override_inject_http_inbound.
  ///
  /// In en, this message translates to:
  /// **'You may want to check `Settings` -> `Profile override` -> `Inject http inbound`'**
  String
  get you_may_want_to_check_settings_profile_override_inject_http_inbound;

  /// No description provided for @you_may_want_to_check_settings_profile_override_inject_socks_inbound.
  ///
  /// In en, this message translates to:
  /// **'You may want to check `Settings` -> `Profile override` -> `Inject socks inbound`'**
  String
  get you_may_want_to_check_settings_profile_override_inject_socks_inbound;

  /// No description provided for @connect_cta_start.
  ///
  /// In en, this message translates to:
  /// **'Lets Go'**
  String get connect_cta_start;

  /// No description provided for @connect_cta_stop.
  ///
  /// In en, this message translates to:
  /// **'Lets Stop'**
  String get connect_cta_stop;

  /// No description provided for @home_connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get home_connecting;

  /// No description provided for @home_status_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get home_status_connected;

  /// No description provided for @home_status_disconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get home_status_disconnected;

  /// No description provided for @region_auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get region_auto;

  /// No description provided for @region_label.
  ///
  /// In en, this message translates to:
  /// **'Region: {name}'**
  String region_label(String name);

  /// No description provided for @switch_region.
  ///
  /// In en, this message translates to:
  /// **'Switch Region'**
  String get switch_region;

  /// No description provided for @full_mask.
  ///
  /// In en, this message translates to:
  /// **'Full Mask'**
  String get full_mask;

  /// No description provided for @full_speed.
  ///
  /// In en, this message translates to:
  /// **'Full Speed'**
  String get full_speed;

  /// No description provided for @manage_profiles.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage_profiles;

  /// No description provided for @guide_skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get guide_skip;

  /// No description provided for @guide_next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get guide_next;

  /// No description provided for @guide_start.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get guide_start;

  /// No description provided for @guide_title_1.
  ///
  /// In en, this message translates to:
  /// **'Stable connection'**
  String get guide_title_1;

  /// No description provided for @guide_desc_1.
  ///
  /// In en, this message translates to:
  /// **'One tap to connect. The selected node and core stay on the existing engine.'**
  String get guide_desc_1;

  /// No description provided for @guide_title_2.
  ///
  /// In en, this message translates to:
  /// **'Safe by default'**
  String get guide_title_2;

  /// No description provided for @guide_desc_2.
  ///
  /// In en, this message translates to:
  /// **'Full Mask uses TUN globally. Full Speed keeps the proxy path only.'**
  String get guide_desc_2;

  /// No description provided for @guide_title_3.
  ///
  /// In en, this message translates to:
  /// **'Always ready'**
  String get guide_title_3;

  /// No description provided for @guide_desc_3.
  ///
  /// In en, this message translates to:
  /// **'Switch regions, manage profiles, and keep your current configuration.'**
  String get guide_desc_3;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create_new.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get create_new;

  /// No description provided for @tun2socks.
  ///
  /// In en, this message translates to:
  /// **'Virtual adapter'**
  String get tun2socks;

  /// No description provided for @invalid_core_type.
  ///
  /// In en, this message translates to:
  /// **'Invalid core type'**
  String get invalid_core_type;

  /// No description provided for @invalid_profile.
  ///
  /// In en, this message translates to:
  /// **'Invalid profile'**
  String get invalid_profile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'hi',
    'id',
    'ja',
    'ko',
    'pt',
    'ru',
    'th',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
          case 'TW':
            return AppLocalizationsZhTw();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'id':
      return AppLocalizationsId();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'th':
      return AppLocalizationsTh();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
