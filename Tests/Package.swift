// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "ComponentsTests",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(
            name: "t_components",
            targets: [
                "ComponentsTestFlows",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swift-dsl/HTML.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-dsl/CSS.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-dsl/JS.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Constructors.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Assets.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/TestFlows.git",
            branch: "master"
        ),
        .package(
            path: ".."
        ),
    ],
    targets: [
        .executableTarget(
            name: "ComponentsTestFlows",
            dependencies: [
                .product(
                    name: "MarkupComponents",
                    package: "Components"
                ),
                .product(
                    name: "WebComponents",
                    package: "Components"
                ),
                .product(
                    name: "HTML",
                    package: "HTML"
                ),
                .product(
                    name: "CSS",
                    package: "CSS"
                ),
                .product(
                    name: "JS",
                    package: "JS"
                ),
                .product(
                    name: "Constructors",
                    package: "Constructors"
                ),
                .product(
                    name: "Assets",
                    package: "Assets"
                ),
                .product(
                    name: "TestFlows",
                    package: "TestFlows"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)
