// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "todo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "todo", targets: ["todo"])
    ],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.4.1")
    ],
    targets: [
        .executableTarget(
            name: "todo",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui")
            ]
        )
    ]
)
