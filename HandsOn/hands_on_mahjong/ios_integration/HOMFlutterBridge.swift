// HOMFlutterBridge.swift
// 在宿主 iOS 项目中引入此文件即可加载 Flutter 游戏

import UIKit
import Flutter

/// 单例 Flutter Engine，供宿主 App 复用
final class HOMFlutterEngine {
    static let shared = HOMFlutterEngine()

    let engine: FlutterEngine
    private var hapticChannel: FlutterMethodChannel?

    private init() {
        engine = FlutterEngine(name: "hands_on_mahjong_engine")
        engine.run(withEntrypoint: nil, libraryURI: nil)
        setupHapticChannel()
    }

    private func setupHapticChannel() {
        hapticChannel = FlutterMethodChannel(
            name: "com.example.handsOnMahjong/haptic",
            binaryMessenger: engine.binaryMessenger
        )
        hapticChannel?.setMethodCallHandler { [weak self] call, result in
            HOMHapticHandler.shared.handle(call: call, result: result)
        }
    }
}

/// 宿主 App 调用此方法打开游戏
extension UIViewController {
    func presentHandsOnMahjong(animated: Bool = true) {
        let vc = FlutterViewController(
            engine: HOMFlutterEngine.shared.engine,
            nibName: nil,
            bundle: nil
        )
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: animated)
    }
}
