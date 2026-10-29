// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Skylet",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SkyletCore", targets: ["SkyletCore"]),
        // A droplet is a loadable bundle, so its product is a dynamic library.
        .library(name: "Skylet", type: .dynamic, targets: ["Skylet"])
    ],
    dependencies: [
        .package(url: "https://gitlab.com/droppyformac1/droppykit.git", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "SkyletCore",
            dependencies: [],
            path: "Sources/SkyletCore"
        ),
        .executableTarget(
            name: "SkyletTestsRunner",
            dependencies: ["SkyletCore"],
            path: "Sources/SkyletTestsRunner"
        ),
        .target(
            name: "Skylet",
            dependencies: [
                "SkyletCore",
                .product(name: "DroppyKit", package: "droppykit")
            ],
            path: "Sources/Skylet"
        ),
        .executableTarget(
            name: "SkyletHarness",
            dependencies: [
                "Skylet",
                .product(name: "DroppyKitHarness", package: "droppykit")
            ],
            path: "Sources/SkyletHarness"
        )
    ]
)
