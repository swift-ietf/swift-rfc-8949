// swift-tools-version: 6.4

import PackageDescription

let package = Package(
    name: "swift-rfc-8949",
    platforms: [
        .macOS(.v27),
        .iOS(.v27),
        .tvOS(.v27),
        .watchOS(.v27),
        .visionOS(.v27),
    ],
    products: [
        .library(name: "RFC 8949", targets: ["RFC 8949"])
    ],
    dependencies: [
        .package(url: "https://github.com/swift-ietf/swift-rfc.git", branch: "main"),],
    targets: [
        .target(
            name: "RFC 8949",
            dependencies: [.product(name: "IETF RFC", package: "swift-rfc"), ]
        ),
        .testTarget(
            name: "RFC 8949 Tests",
            dependencies: [
                .target(name: "RFC 8949")
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
