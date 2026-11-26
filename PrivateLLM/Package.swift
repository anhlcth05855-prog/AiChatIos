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
    dependencies: [
        .package(url: "https://github.com/mattt/llama.swift", exact: "2.10549.0")
    ],
    targets: [
        .target(
            name: "PrivateLLMKit",
            dependencies: [
                .product(name: "LlamaSwift", package: "llama.swift")
            ],
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
