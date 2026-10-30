// swift-tools-version: 6.0
import PackageDescription
import Foundation

let droppyKitDependency: Package.Dependency
let droppyKitPackageName: String

if let localPath = ProcessInfo.processInfo.environment["DROPPYKIT_PATH"], !localPath.isEmpty {
    droppyKitDependency = .package(path: localPath)
    droppyKitPackageName = "DroppyKit"
} else {
    droppyKitDependency = .package(url: "https://gitlab.com/droppyformac1/droppykit.git", from: "1.6.0")
    droppyKitPackageName = "droppykit"
}

let package = Package(
    name: "Skylet",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SkyletCore", targets: ["SkyletCore"]),
        // A droplet is a loadable bundle, so its product is a dynamic library.
        .library(name: "Skylet", type: .dynamic, targets: ["Skylet"])
    ],
    dependencies: [
        droppyKitDependency
    ],
    targets: [
        .target(
            name: "SkyletCore",
            dependencies: [],
            path: "Sources/SkyletCore"
        ),
        .target(
            name: "Skylet",
            dependencies: [
                "SkyletCore",
                .product(name: "DroppyKit", package: droppyKitPackageName)
            ],
            path: "Sources/Skylet"
        ),
        .executableTarget(
            name: "SkyletHarness",
            dependencies: [
                "Skylet",
                .product(name: "DroppyKitHarness", package: droppyKitPackageName)
            ],
            path: "Sources/SkyletHarness"
        ),
        .executableTarget(
            name: "SkyletTestsRunner",
            dependencies: ["SkyletCore"],
            path: "Sources/SkyletTestsRunner"
        )
    ]
)
