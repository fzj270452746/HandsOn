# iOS 宿主项目集成指南

## Framework 输出位置

```
FlutterFramework/
├── Debug/
│   ├── App.xcframework                    ← Flutter 业务代码
│   ├── Flutter.xcframework                ← Flutter engine
│   ├── FlutterPluginRegistrant.xcframework
│   └── shared_preferences_foundation.xcframework
└── Release/
    └── (同上，Release 编译产物)
```

## Xcode 集成步骤

### 1. 添加 Frameworks

在宿主项目 → Target → General → Frameworks, Libraries, and Embedded Content 中添加以下（以 Debug 为例，Release 同理）：

| Framework | Embed |
|-----------|-------|
| Flutter.xcframework | Embed & Sign |
| App.xcframework | Embed & Sign |
| FlutterPluginRegistrant.xcframework | Embed & Sign |
| shared_preferences_foundation.xcframework | Embed & Sign |

### 2. 复制 iOS 集成文件

将 `hands_on_mahjong/ios_integration/` 下两个文件加入宿主项目：
- `HOMFlutterBridge.swift`
- `HOMHapticHandler.swift`

### 3. 添加 CoreHaptics 框架

Target → Frameworks, Libraries → 搜索 `CoreHaptics.framework`，选 **Do Not Embed**

### 4. 启动游戏

```swift
// 任意 UIViewController 中：
import UIKit

class YourViewController: UIViewController {
    @IBAction func openGame(_ sender: Any) {
        presentHandsOnMahjong()   // HOMFlutterBridge.swift 里的扩展方法
    }
}
```

### 5. Build Settings

- `SWIFT_VERSION` = 5.0+
- Deployment Target ≥ iOS 15.0
- 如需真机 Debug，参考 Flutter 文档配置 LLDB Init File

## 重新构建 Framework

```bash
cd hands_on_mahjong
flutter build ios-framework --output=../FlutterFramework --no-profile --no-codesign
```

Release 包请去掉 `--no-codesign` 并配置正确的签名证书。
