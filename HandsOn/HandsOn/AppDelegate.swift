

import UIKit
import Flutter
import FlutterPluginRegistrant
import CoreHaptics
import AppTrackingTransparency

@main
class AppDelegate: FlutterAppDelegate {
    
//    var window: UIWindow?
    
    lazy var flutterEngine = FlutterEngine(name: "main_engine")

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let hapticChannel = FlutterMethodChannel(
            name: "com.HO.HandsOn/haptic",
            binaryMessenger: flutterEngine.binaryMessenger
        )
        
        flutterEngine.run()
        
        hapticChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "impact":
                let style = call.arguments as? String
                let generator: UIImpactFeedbackGenerator
                switch style {
                case "heavy":  generator = UIImpactFeedbackGenerator(style: .heavy)
                case "medium": generator = UIImpactFeedbackGenerator(style: .medium)
                default:       generator = UIImpactFeedbackGenerator(style: .light)
                }
                generator.impactOccurred()
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        GeneratedPluginRegistrant.register(with: flutterEngine)

        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: HOHomeViewController())
        window?.makeKeyAndVisible()

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ATTrackingManager.requestTrackingAuthorization {_ in }
        }
    }
}

