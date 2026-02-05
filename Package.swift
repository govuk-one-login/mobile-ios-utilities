// swift-tools-version: 6.2

import PackageDescription

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
    dependencies: [
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            .upToNextMajor(from: "0.58.2")
        )
    ],
    targets: [
        .target(
            name: "GDSUtilities",
            plugins: [
                .plugin(name: "SwiftLintBuildToolPlugin", package: "SwiftLintPlugins")
            ]
        ),
        .testTarget(
            name: "GDSUtilitiesTests",
            dependencies: ["GDSUtilities"]
        )
    ]
)
