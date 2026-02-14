import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Register the Live Activity bridge so Flutter can start / update / end
    // the lock-screen countdown via the same MethodChannel used on Android.
    if let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "TimerLiveActivityManager"
    ) {
      TimerLiveActivityManager.register(with: registrar)
    }
  }
}
