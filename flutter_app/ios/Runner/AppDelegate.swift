import Flutter
import UIKit
import workmanager
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, UNUserNotificationCenterDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Allow notifications to show as banners even when the app is in the foreground
    UNUserNotificationCenter.current().delegate = self

    // Register background task identifiers for WorkManager
    WorkmanagerPlugin.registerTask(withIdentifier: "be.tramckrijte.workmanagerExample.iOSBackgroundAppRefresh")
    WorkmanagerPlugin.registerBGProcessingTask(withIdentifier: "be.tramckrijte.workmanagerExample.iOSBackgroundProcessing")

    // Enable background fetch
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Show banner + sound when notification arrives while app is in foreground
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.alert, .badge, .sound])
  }
}
