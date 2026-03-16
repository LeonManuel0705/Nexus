import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'sync_manager.dart';
import 'offline_queue.dart';
import 'database_service.dart' if (dart.library.html) 'database_service_web.dart';
import 'iserv_service.dart';

bool get _isBackgroundSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

bool get _isDesktop {
  if (kIsWeb) return false;
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

const String kEmailSyncTask = 'emailSync';
const String kCalendarSyncTask = 'calendarSync';
const String kIServSyncTask = 'iservSync';
const String kCacheCleanupTask = 'cacheCleanup';
const String kOfflineQueueTask = 'offlineQueue';
const String kUpdateCheckTask = 'updateCheck';

/// Initialize flutter_local_notifications for the background isolate.
Future<FlutterLocalNotificationsPlugin> _initBackgroundNotifications() async {
  final plugin = FlutterLocalNotificationsPlugin();
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings(
    requestAlertPermission: false,
    requestBadgePermission: false,
    requestSoundPermission: false,
  );
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );
  await plugin.initialize(initSettings);
  return plugin;
}

/// Show a notification from the background isolate.
Future<void> _showBackgroundNotification(
  FlutterLocalNotificationsPlugin plugin, {
  required int id,
  required String title,
  required String body,
  String channelId = 'nexus_background',
  String channelName = 'Hintergrund-Benachrichtigungen',
}) async {
  final androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: 'Benachrichtigungen während die App im Hintergrund läuft',
    importance: Importance.high,
    priority: Priority.high,
  );
  const iosDetails = DarwinNotificationDetails();
  final details = NotificationDetails(
    android: androidDetails,
    iOS: iosDetails,
  );
  await plugin.show(id, title, body, details);
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      switch (task) {
        case kEmailSyncTask:
          await _syncEmail();
          break;
        case kCalendarSyncTask:
          await _syncCalendar();
          break;
        case kIServSyncTask:
          await _syncIServWithNotifications();
          break;
        case kCacheCleanupTask:
          await _cleanupCache();
          break;
        case kOfflineQueueTask:
          await _processOfflineQueue();
          break;
        case kUpdateCheckTask:
          await _checkForUpdateInBackground();
          break;
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('BackgroundService: task=$task error: $e');
      return false;
    }
  });
}

Future<void> _syncEmail() async {
  final syncManager = SyncManager();
  await syncManager.syncEmail();
}

Future<void> _syncCalendar() async {
  final syncManager = SyncManager();
  await syncManager.syncCalendar();
}

/// IServ sync with background notification support.
/// Compares cached notification IDs before/after sync and shows
/// system notifications for new unread items.
Future<void> _syncIServWithNotifications() async {
  final now = DateTime.now();
  if (now.hour < 6 || now.hour >= 20) return;
  if (now.weekday > 5) return;

  try {
    final iservService = IServService();
    final connected = await iservService.autoReconnect();
    if (!connected) return;

    // Snapshot cached notification IDs before sync
    final cachedBefore = await iservService.getCachedNotifications();
    final previousIds = cachedBefore.map((n) => n.id).toSet();

    // Sync all IServ data (caches new notifications to DB)
    await iservService.syncAll();

    // Load fresh notifications and find new unread ones
    final fresh = await iservService.getCachedNotifications();
    final newUnread = fresh.where(
      (n) => !n.read && !previousIds.contains(n.id),
    ).toList();

    if (newUnread.isEmpty) return;

    // Initialize notifications plugin in background isolate and show alerts
    final plugin = await _initBackgroundNotifications();
    for (final n in newUnread) {
      await _showBackgroundNotification(
        plugin,
        id: n.id.hashCode,
        title: n.title,
        body: n.message ?? 'Neue IServ-Benachrichtigung',
        channelId: 'nexus_iserv',
        channelName: 'IServ',
      );
    }
  } catch (_) {}
}

/// Check for app updates in the background and notify the user.
Future<void> _checkForUpdateInBackground() async {
  try {
    final response = await http.get(
      Uri.parse('https://nexus-lifehub.netlify.app/version.json'),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return;

    final data = json.decode(response.body);
    final remoteVersion = data['version'] as String?;
    if (remoteVersion == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastNotifiedVersion = prefs.getString('bg_update_notified_version');
    final skippedVersion = prefs.getString('update_skipped_version');
    final currentVersion = prefs.getString('current_app_version') ?? '';

    // Don't notify if already notified, skipped, or same version
    if (remoteVersion == lastNotifiedVersion) return;
    if (remoteVersion == skippedVersion) return;
    if (remoteVersion == currentVersion) return;
    if (!_isNewerVersion(remoteVersion, currentVersion)) return;

    final versionName = data['versionName'] as String? ?? remoteVersion;

    final plugin = await _initBackgroundNotifications();
    await _showBackgroundNotification(
      plugin,
      id: 9999,
      title: 'Nexus Update verfügbar',
      body: '$versionName ist jetzt verfügbar.',
      channelId: 'nexus_updates',
      channelName: 'Updates',
    );

    await prefs.setString('bg_update_notified_version', remoteVersion);
  } catch (_) {}
}

bool _isNewerVersion(String remote, String current) {
  if (current.isEmpty) return true;
  try {
    final remoteParts = remote.split('.').map(int.parse).toList();
    final currentParts = current.split('.').map(int.parse).toList();
    for (int i = 0; i < remoteParts.length && i < currentParts.length; i++) {
      if (remoteParts[i] > currentParts[i]) return true;
      if (remoteParts[i] < currentParts[i]) return false;
    }
    return remoteParts.length > currentParts.length;
  } catch (e) {
    return remote != current;
  }
}

Future<void> _cleanupCache() async {
  final db = DatabaseService();
  await db.cleanupOldCache();
}

Future<void> _processOfflineQueue() async {
  final queue = OfflineQueue();
  await queue.processQueue();
}

class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;
  Timer? _desktopSyncTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isDesktop) {
      _isInitialized = true;
      return;
    }
    if (!_isBackgroundSupported) {
      _isInitialized = true;
      return;
    }

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    _isInitialized = true;
  }

  Future<void> registerTasks() async {
    if (_isDesktop) {
      _desktopSyncTimer?.cancel();
      _desktopSyncTimer = Timer.periodic(
        const Duration(minutes: 15),
        (_) => _runDesktopSync(),
      );
      return;
    }
    if (!_isBackgroundSupported) return;
    await initialize();

    await Workmanager().registerPeriodicTask(
      'email_sync_periodic',
      kEmailSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      'calendar_sync_periodic',
      kCalendarSyncTask,
      frequency: const Duration(minutes: 30),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      'iserv_sync_periodic',
      kIServSyncTask,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
        requiresBatteryNotLow: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      'update_check_periodic',
      kUpdateCheckTask,
      frequency: const Duration(hours: 2),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      'cache_cleanup_periodic',
      kCacheCleanupTask,
      frequency: const Duration(hours: 24),
      initialDelay: _getDelayUntil3AM(),
      constraints: Constraints(
        networkType: NetworkType.not_required,
        requiresBatteryNotLow: true,
        requiresCharging: true,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    await Workmanager().registerPeriodicTask(
      'offline_queue_periodic',
      kOfflineQueueTask,
      frequency: const Duration(minutes: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );
  }

  Future<void> cancelAllTasks() async {
    if (_isDesktop) {
      _desktopSyncTimer?.cancel();
      _desktopSyncTimer = null;
      return;
    }
    if (!_isBackgroundSupported) return;
    await Workmanager().cancelAll();
  }

  Future<void> cancelTask(String taskName) async {
    if (!_isBackgroundSupported) return;
    await Workmanager().cancelByUniqueName(taskName);
  }

  Future<void> syncNow() async {
    if (_isDesktop) {
      await _runDesktopSync();
      return;
    }
    if (!_isBackgroundSupported) return;
    await initialize();

    await Workmanager().registerOneOffTask(
      'immediate_sync',
      kEmailSyncTask,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  Future<void> _runDesktopSync() async {
    try {
      final iservService = IServService();
      final connected = await iservService.autoReconnect();
      if (connected) {
        await iservService.syncAll();
      }
      final syncManager = SyncManager();
      await syncManager.syncCalendar();
    } catch (_) {}
  }

  Duration _getDelayUntil3AM() {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 3, 0);

    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    return target.difference(now);
  }
}

extension SyncManagerBackground on SyncManager {
  Future<void> syncEmail() async {

  }

  Future<void> syncCalendar() async {

  }

  Future<void> syncIServ() async {
    final now = DateTime.now();
    if (now.hour < 6 || now.hour >= 20) return;
    if (now.weekday > 5) return;

    try {
      final iservService = IServService();
      final connected = await iservService.autoReconnect();
      if (connected) {
        await iservService.syncAll();
      }
    } catch (_) {}
  }
}

extension DatabaseServiceCleanup on DatabaseService {
  Future<void> cleanupOldCache() async {

  }
}
