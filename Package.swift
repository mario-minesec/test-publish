// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Headless",                 // package name (repo-level)
    platforms: [
        .iOS(.v13)                    // change minimum iOS if needed
    ],
    products: [
        .library(
            name: "Headless",         // product name clients will add & import
            targets: ["Headless"]
        )
    ],
    targets: [
        .binaryTarget(
            name: "Headless",         // MUST match the framework module name
            path: "Headless.xcframework" // MUST match the xcframework folder name
        )
    ]
)
