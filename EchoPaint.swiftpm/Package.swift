// swift-tools-version: 5.9

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "EchoPaint",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "EchoPaint",
            targets: ["EchoPaint"],
            bundleIdentifier: "com.swiftstudent.echopaint",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .pencil),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "EchoPaint",
            path: ".",
            exclude: ["README.md", "Package.swift.metadata"],
            sources: [
                "EchoPaintApp.swift",
                "ContentView.swift",
                "Audio/SoundEngine.swift",
                "Haptics/HapticEngine.swift",
                "Models/DrawingPath.swift",
                "Models/TouchPoint.swift",
                "Views/CanvasView.swift",
                "Views/ControlPanelView.swift"
            ]
        )
    ]
)
