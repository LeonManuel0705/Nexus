import Flutter
import UIKit
import workmanager
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    UNUserNotificationCenter.current().delegate = self

    // Register each BGAppRefresh task identifier the Dart code schedules. These
    // MUST match the uniqueNames in background_service.dart AND the
    // BGTaskSchedulerPermittedIdentifiers in Info.plist, otherwise
    // BGTaskScheduler rejects the submissions and no background task ever runs.
    // registerPeriodicTask installs a BGAppRefreshTask handler (the correct
    // type) — unlike the old registerTask, which wrongly installed a
    // BGProcessingTask handler.
    let refreshIdentifiers = [
      "email_sync_periodic",
      "calendar_sync_periodic",
      "iserv_sync_periodic",
      "update_check_periodic",
      "cache_cleanup_periodic",
      "offline_queue_periodic",
    ]
    for identifier in refreshIdentifiers {
      WorkmanagerPlugin.registerPeriodicTask(withIdentifier: identifier, frequency: NSNumber(value: 15 * 60))
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .badge, .sound])
  }
}
