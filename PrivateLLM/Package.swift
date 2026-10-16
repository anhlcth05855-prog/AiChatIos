// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PrivateLLM",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "PrivateLLMKit",
            targets: ["PrivateLLMKit"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PrivateLLMKit",
            dependencies: [],
            path: ".",
            exclude: [
                "PrivateLLM.xcodeproj",
                "App/PrivateLLMApp.swift"
            ],
            sources: [
                "Models",
                "Engines",
                "Repositories",
                "Intents",
                "Utilities",
                "ViewModels",
                "Views"
            ]
        )
    ]
)
