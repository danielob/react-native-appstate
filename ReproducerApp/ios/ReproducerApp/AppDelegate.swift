import UIKit
import React
import React_RCTAppDelegate
import ReactAppDependencyProvider

// Reproducer: this app uses the UIScene lifecycle (see UIApplicationSceneManifest
// in Info.plist). The React Native window is created in SceneDelegate instead of
// AppDelegate.application(_:didFinishLaunchingWithOptions:).

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var reactNativeDelegate: ReactNativeDelegate?
  var reactNativeFactory: RCTReactNativeFactory?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    let delegate = ReactNativeDelegate()
    let factory = RCTReactNativeFactory(delegate: delegate)
    delegate.dependencyProvider = RCTAppDependencyProvider()

    reactNativeDelegate = delegate
    reactNativeFactory = factory

    LifecycleLogger.shared.start()

    return true
  }

  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene,
          let appDelegate = UIApplication.shared.delegate as? AppDelegate,
          let factory = appDelegate.reactNativeFactory else { return }

    let window = UIWindow(windowScene: windowScene)
    self.window = window

    factory.startReactNative(
      withModuleName: "ReproducerApp",
      in: window,
      launchOptions: nil
    )
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    LifecycleLogger.log("SceneDelegate.sceneDidBecomeActive")
  }

  func sceneWillResignActive(_ scene: UIScene) {
    LifecycleLogger.log("SceneDelegate.sceneWillResignActive")
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    LifecycleLogger.log("SceneDelegate.sceneWillEnterForeground")
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    LifecycleLogger.log("SceneDelegate.sceneDidEnterBackground")
  }
}

/// Logs the UIApplication notifications RCTAppState listens to, plus the UIScene
/// notifications it does not, along with UIApplication.applicationState at that
/// moment. Filter Xcode's console with "[Lifecycle]".
final class LifecycleLogger {
  static let shared = LifecycleLogger()

  private let names: [Notification.Name] = [
    // Observed by RCTAppState.mm
    UIApplication.didBecomeActiveNotification,
    UIApplication.willResignActiveNotification,
    UIApplication.didEnterBackgroundNotification,
    UIApplication.willEnterForegroundNotification,
    // Not observed by RCTAppState.mm
    UIScene.didActivateNotification,
    UIScene.willDeactivateNotification,
    UIScene.didEnterBackgroundNotification,
    UIScene.willEnterForegroundNotification,
  ]

  func start() {
    for name in names {
      NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { note in
        LifecycleLogger.log("Notification \(note.name.rawValue)")
      }
    }
  }

  static func log(_ event: String) {
    let state: String
    switch UIApplication.shared.applicationState {
    case .active: state = "active"
    case .inactive: state = "inactive"
    case .background: state = "background"
    @unknown default: state = "unknown"
    }
    NSLog("[Lifecycle] %@ | applicationState=%@", event, state)
  }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  override func bundleURL() -> URL? {
#if DEBUG
    RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
#else
    Bundle.main.url(forResource: "main", withExtension: "jsbundle")
#endif
  }
}
