// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Components",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "MarkupComponents",
            targets: [
                "MarkupComponents",
            ]
        ),
        .library(
            name: "WebComponents",
            targets: [
                "WebComponents",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Macros.git",
            branch: "master"
        ),
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
            url: "https://github.com/swift-webc/Constructors.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Version.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Difference.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/References.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/leviouwendijk/Assets.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "MarkupComponents",
            dependencies: [
                .product(
                    name: "Macros",
                    package: "Macros"
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
                    name: "Constructors",
                    package: "Constructors"
                ),
            ]
        ),
        .target(
            name: "WebComponents",
            dependencies: [
                .product(
                    name: "Primitives",
                    package: "Primitives"
                ),
                .product(
                    name: "Macros",
                    package: "Macros"
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
                    name: "Version",
                    package: "Version"
                ),
                .product(
                    name: "Difference",
                    package: "Difference"
                ),
                .product(
                    name: "References",
                    package: "References"
                ),
                .product(
                    name: "Assets",
                    package: "Assets"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)
