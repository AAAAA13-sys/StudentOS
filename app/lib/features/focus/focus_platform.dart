import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phone settings that decide whether alarms ring and lockdown holds.
class PhoneReadiness {
  const PhoneReadiness({
    this.notifications = true,
    this.exactAlarms = true,
    this.fullScreen = true,
    this.batteryUnrestricted = true,
    this.overlay = true,
    this.accessibility = false,
  });

  factory PhoneReadiness.fromMap(Map<Object?, Object?> map) => PhoneReadiness(
    notifications: map['notifications'] as bool? ?? true,
    exactAlarms: map['exactAlarms'] as bool? ?? true,
    fullScreen: map['fullScreen'] as bool? ?? true,
    batteryUnrestricted: map['battery'] as bool? ?? true,
    overlay: map['overlay'] as bool? ?? true,
    accessibility: map['accessibility'] as bool? ?? false,
  );

  final bool notifications;
  final bool exactAlarms;

  /// Lets a ringing alarm take over the lock screen.
  final bool fullScreen;
  final bool batteryUnrestricted;

  /// "Display over other apps": lets the alarm screen open on top of
  /// whatever is in use.
  final bool overlay;

  /// The strict-lockdown service is turned on.
  final bool accessibility;

  bool get alarmsReady =>
      notifications && exactAlarms && fullScreen && batteryUnrestricted;
}

/// A launchable app, for the strict-lockdown allow list.
class InstalledApp {
  const InstalledApp(this.package, this.label);

  final String package;
  final String label;
}

/// Everything the Focus tab asks of Android; replaced by a fake in tests.
abstract class FocusPlatform {
  /// Hands Android the full alarm list; it schedules the enabled ones.
  Future<void> syncAlarms(List<Map<String, Object?>> alarms);

  /// Ids of one-time alarms that rang since the last call; the app turns
  /// them off in its own list.
  Future<List<int>> takeFiredOnce();

  /// Rings [alarm] right away so its settings can be tried.
  Future<void> testAlarm(Map<String, Object?> alarm);

  /// Opens Android's sound picker. Null when nothing was chosen; an empty
  /// uri means the phone's default alarm.
  Future<({String uri, String name})?> pickSound(String? current);

  Future<PhoneReadiness> readiness();

  /// Opens the system screen for one readiness item (the field names of
  /// [PhoneReadiness]).
  Future<void> openSetting(String which);

  /// Starts holding the phone and ringing phase changes for a session.
  Future<void> startFocus(Map<String, Object?> session);

  Future<void> stopFocus();

  /// Light lockdown: Android screen pinning of this app.
  Future<void> setPinned(bool pinned);

  Future<List<InstalledApp>> launchableApps();

  /// A route Android asked the app to open (e.g. after strict lockdown sent
  /// the user back), taken once.
  Future<String?> takeRoute();

  /// Asks the launcher to put one of the widgets (`calendar`, `finance` or
  /// `clock`) on the home screen. False when the launcher cannot.
  Future<bool> pinWidget(String which);

  /// Calls [onRoute] whenever Android has a route waiting while the app is
  /// already open; the route is then read with [takeRoute].
  void onRouteWaiting(void Function() onRoute);
}

/// Whether [route] from Android means "open the focus timer". `/focus` is
/// what the first build of the Focus tab sent.
bool isTimerRoute(String? route) => route == 'timer' || route == '/focus';

class ChannelFocusPlatform implements FocusPlatform {
  const ChannelFocusPlatform();

  static const MethodChannel _channel = MethodChannel('com.studentos/focus');

  Future<T?> _call<T>(String method, [Object? args]) async {
    try {
      return await _channel.invokeMethod<T>(method, args);
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> syncAlarms(List<Map<String, Object?>> alarms) =>
      _call<void>('syncAlarms', <String, Object?>{'alarms': alarms});

  @override
  Future<List<int>> takeFiredOnce() async {
    final List<Object?>? ids = await _call<List<Object?>>('takeFiredOnce');
    return <int>[
      for (final Object? id in ids ?? <Object?>[])
        if (id is num) id.toInt(),
    ];
  }

  @override
  Future<void> testAlarm(Map<String, Object?> alarm) =>
      _call<void>('testAlarm', <String, Object?>{'alarm': alarm});

  @override
  Future<({String uri, String name})?> pickSound(String? current) async {
    final Map<Object?, Object?>? picked = await _call<Map<Object?, Object?>>(
      'pickSound',
      <String, Object?>{'current': current},
    );
    if (picked == null) return null;
    return (
      uri: picked['uri'] as String? ?? '',
      name: picked['name'] as String? ?? 'Alarm sound',
    );
  }

  @override
  Future<PhoneReadiness> readiness() async {
    final Map<Object?, Object?>? map = await _call<Map<Object?, Object?>>(
      'readiness',
    );
    return map == null ? const PhoneReadiness() : PhoneReadiness.fromMap(map);
  }

  @override
  Future<void> openSetting(String which) =>
      _call<void>('openSetting', <String, Object?>{'which': which});

  @override
  Future<void> startFocus(Map<String, Object?> session) =>
      _call<void>('startFocus', <String, Object?>{'session': session});

  @override
  Future<void> stopFocus() => _call<void>('stopFocus');

  @override
  Future<void> setPinned(bool pinned) =>
      _call<void>('setPinned', <String, Object?>{'pinned': pinned});

  @override
  Future<List<InstalledApp>> launchableApps() async {
    final List<Object?>? apps = await _call<List<Object?>>('launchableApps');
    return <InstalledApp>[
      for (final Object? raw in apps ?? <Object?>[])
        if (raw is Map<Object?, Object?>)
          InstalledApp(raw['package']! as String, raw['label']! as String),
    ]..sort(
      (InstalledApp a, InstalledApp b) =>
          a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
  }

  @override
  Future<String?> takeRoute() => _call<String>('takeRoute');

  @override
  Future<bool> pinWidget(String which) async =>
      await _call<bool>('pinWidget', <String, Object?>{'which': which}) ??
      false;

  @override
  void onRouteWaiting(void Function() onRoute) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'openRoute') onRoute();
    });
  }
}

final Provider<FocusPlatform> focusPlatformProvider = Provider<FocusPlatform>(
  (ref) => const ChannelFocusPlatform(),
);
