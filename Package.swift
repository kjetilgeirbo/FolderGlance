// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FolderGlance",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "FolderGlance",
            path: "Sources/FolderGlance"
        ),
        .testTarget(
            name: "FolderGlanceTests",
            dependencies: ["FolderGlance"],
            path: "Tests/FolderGlanceTests"
        ),
    ]
)
