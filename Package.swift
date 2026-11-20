// swift-tools-version: 5.9
import PackageDescription
let package = Package(
    name: "Kova",
    platforms: [.iOS(.v17)],
    products: [.library(name: "Kova", targets: ["Kova"])],
    targets: [.target(name: "Kova", path: "Sources/Kova", resources: [.process("Resources")])]
)
