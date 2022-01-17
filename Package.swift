// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "SensorsAnalyticsSDK",
    platforms: [ 
        .iOS(.v8)
    ],
    products: [
        .library(
            name: "SensorsAnalyticsSDK",
            targets: ["SensorsAnalyticsSDK"])
    ],
    targets: [
      .target(
            name: "SensorsAnalyticsSDK",
            path: "SensorsAnalyticsSDK",
            exclude: ["AppPush", "CAID", "WebView", "WKWebView", "Location", "DeviceOrientation", "Exception"],
            resources: [.copy("SensorsAnalyticsSDK.bundle")],
            cSettings: [
                .headerSearchPath("."),
                .headerSearchPath("Visualized"),
                .headerSearchPath("Visualized/Config"),
                .headerSearchPath("Visualized/ElementPath"),
                .headerSearchPath("Visualized/EventCheck"),
                .headerSearchPath("Visualized/ElementSelector"),
                .headerSearchPath("Visualized/VisualProperties"),
                .headerSearchPath("Visualized/VisualProperties/ViewNode"),
                .headerSearchPath("Visualized/VisualProperties/DebugLog"),
                .headerSearchPath("Visualized/WebElementInfo"),
                .headerSearchPath("Core"),
                .headerSearchPath("Core/Builder"),
                .headerSearchPath("Core/SALogger"),
                .headerSearchPath("Core/Utils"),
                .headerSearchPath("Core/Tracker"),
                .headerSearchPath("Core/Builder/EventObject"),
                .headerSearchPath("Core/HookDelegate"),
                .headerSearchPath("Core/Network"),
                .headerSearchPath("Encrypt"),
                .headerSearchPath("JSBridge"),
                .headerSearchPath("DebugMode"),
                .headerSearchPath("ChannelMatch"),
                .headerSearchPath("Deeplink"),
                .headerSearchPath("RemoteConfig"),
                .headerSearchPath("AutoTrack"),
                .headerSearchPath("AutoTrack/AppClick"),
                .headerSearchPath("AutoTrack/AppClick/Cell"),
                .headerSearchPath("AutoTrack/AppClick/Gesture"),
                .headerSearchPath("AutoTrack/AppClick/Gesture/Target"),
                .headerSearchPath("AutoTrack/AppClick/Gesture/Processor"),
                .headerSearchPath("AutoTrack/AppViewScreen"),
                .headerSearchPath("AutoTrack/AppPageLeave"),
                .headerSearchPath("AutoTrack/AppStart"),
                .headerSearchPath("AutoTrack/AppEnd"),
                .headerSearchPath("AutoTrack/ElementInfo"),
            ]
        )
    ]
)
