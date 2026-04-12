// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MyataStaticMenuSwift",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "MyataStaticMenuSwift", targets: ["MyataStaticMenuSwift"]),
    ],
    targets: [
        .executableTarget(
            name: "MyataStaticMenuSwift",
            path: "Sources/MyataStaticMenuSwift"
        ),
    ]
)
