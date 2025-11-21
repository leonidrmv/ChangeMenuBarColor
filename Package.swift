// swift-tools-version:6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChangeMenuBarColor",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ChangeMenuBarColor", targets: ["ChangeMenuBarColor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.2.0")
    ],
    targets: [
        .executableTarget(
            name: "ChangeMenuBarColor",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Rainbow", package: "Rainbow"),
                .product(name: "Files", package: "Files")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .unsafeFlags(["-strict-concurrency=minimal"])
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
