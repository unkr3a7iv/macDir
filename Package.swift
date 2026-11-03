// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QDirMac",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "QDirMac",
            path: "QDirMac",
            resources: [
                .copy("Resources")
            ]
        )
    ]
)
