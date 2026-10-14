// swift-tools-version: 6.2

import PackageDescription

// Detect if this package is being built as a remote dependency checkout
let isDependencyCheckout = #filePath.contains("/checkouts/")

var dependencies: [Package.Dependency] = []
var plugins: [Target.PluginUsage] = []

// Only add SwiftLint when developing locally, NOT when consumed as a dependency
if !isDependencyCheckout {
    dependencies.append(
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            .upToNextMajor(from: "0.58.2")
        )
    )
    plugins.append(
        .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
    )
}

let package = Package(
    name: "GDSUtilities",
    defaultLocalization: "en",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(
            name: "GDSUtilities",
            targets: ["GDSUtilities"]
        )
    ],
    dependencies: dependencies,
    targets: [
        .target(
            name: "GDSUtilities",
            plugins: plugins
        ),
        .testTarget(
            name: "GDSUtilitiesTests",
            dependencies: ["GDSUtilities"]
        )
    ]
)
