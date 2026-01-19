import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:workmanager/workmanager.dart';
import 'sync_manager.dart';
import 'offline_queue.dart';
import 'database_service.dart' if (dart.library.html) 'database_service_web.dart';

/// Check if background tasks are supported on this platform
bool get _isBackgroundSupported {
  if (kIsWeb) return false;
  return Platform.isAndroid || Platform.isIOS;
}

const String kEmailSyncTask = 'emailSync';
const String kCalendarSyncTask = 'calendarSync';
const String kIServSyncTask = 'iservSync';
const String kCacheCleanupTask = 'cacheCleanup';
const String kOfflineQueueTask = 'offlineQueue';

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
          await _syncIServ();
          break;
        case kCacheCleanupTask:
          await _cleanupCache();
          break;
        case kOfflineQueueTask:
          await _processOfflineQueue();
          break;
      }
      return true;
    } catch (e) {
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

Future<void> _syncIServ() async {
  final syncManager = SyncManager();
  await syncManager.syncIServ();
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

  Future<void> initialize() async {
    if (_isInitialized) return;
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
    if (!_isBackgroundSupported) return;
    await Workmanager().cancelAll();
  }

  Future<void> cancelTask(String taskName) async {
    if (!_isBackgroundSupported) return;
    await Workmanager().cancelByUniqueName(taskName);
  }

  Future<void> syncNow() async {
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

  }
}

extension DatabaseServiceCleanup on DatabaseService {
  Future<void> cleanupOldCache() async {

  }
}
