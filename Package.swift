// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "GDSUtilities",
    defaultLocalization: "en",
    platforms: [.iOS(.v16)],
    products: [
        .library(
            name: "GDSUtilities",
            targets: ["GDSUtilities"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/govuk-one-login/mobile-ios-logging",
            .upToNextMajor(from: "5.0.0")
        ),
        .package(
            url: "https://github.com/SimplyDanny/SwiftLintPlugins",
            .upToNextMajor(from: "0.58.2")
        )
    ],
    targets: [
        .target(
            name: "GDSUtilities",
            dependencies: [
                .product(name: "GDSAnalytics", package: "mobile-ios-logging"),
            ],
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
