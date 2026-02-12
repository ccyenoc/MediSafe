import GoogleMaps
import flutter_config

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let apiKey = FlutterConfigPlugin.env(for: "GOOGLE_MAPS_API_KEY")
    GMSServices.provideAPIKey(apiKey ?? "")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
