import Cocoa
import FlutterMacOS
import UserNotifications

class MainFlutterWindow: NSWindow, NSWindowDelegate {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    self.setContentSize(NSSize(width: 1280, height: 800))
    self.minSize = NSSize(width: 900, height: 600)
    self.center()
    self.title = "Nexus"

    // Transparent title bar — content extends behind it
    self.titlebarAppearsTransparent = true
    self.titleVisibility = .hidden
    self.styleMask.insert(.fullSizeContentView)

    // Match Nexus dark background to prevent flash on launch
    self.backgroundColor = NSColor(red: 15.0/255, green: 15.0/255, blue: 26.0/255, alpha: 1.0)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Hide window on close instead of destroying it,
    // so the Flutter engine and background tasks keep running
    self.delegate = self

    // Native notification method channel
    let channel = FlutterMethodChannel(
      name: "com.leon.nexus/notifications",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "showNotification" {
        guard let args = call.arguments as? [String: Any],
              let title = args["title"] as? String,
              let body = args["body"] as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: "title and body required", details: nil))
          return
        }
        let id = args["id"] as? Int ?? 0

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
          DispatchQueue.main.async {
            guard settings.authorizationStatus == .authorized else {
              result(FlutterError(code: "NOT_AUTHORIZED",
                                  message: "status=\(settings.authorizationStatus.rawValue)",
                                  details: nil))
              return
            }

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body

            // Use a 1-second delay so macOS shows the banner even in foreground
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
              identifier: "nexus-\(id)-\(Date().timeIntervalSince1970)",
              content: content,
              trigger: trigger
            )
            center.add(request) { error in
              DispatchQueue.main.async {
                if let error = error {
                  result(FlutterError(code: "DELIVERY_ERROR", message: error.localizedDescription, details: nil))
                } else {
                  result(nil)  // success
                }
              }
            }
          }
        }
      } else if call.method == "requestPermissions" {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .badge]) { granted, error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "PERMISSION_ERROR", message: error.localizedDescription, details: nil))
            } else {
              result(granted)
            }
          }
        }
      } else if call.method == "getAuthorizationStatus" {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
          DispatchQueue.main.async {
            result([
              "status": settings.authorizationStatus.rawValue,
              "alertStyle": settings.alertStyle.rawValue,
              "alertSetting": settings.alertSetting.rawValue,
              "notificationCenter": settings.notificationCenterSetting.rawValue,
            ])
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }

  // Hide the window instead of closing it — keeps the Flutter engine alive
  // so background timers, sync, and notifications continue working
  func windowShouldClose(_ sender: NSWindow) -> Bool {
    self.orderOut(nil)
    return false
  }
}
