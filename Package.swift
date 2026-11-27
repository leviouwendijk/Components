// swift-tools-version: 6.3

import CompilerPluginSupport
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
        .library(
            name: "SiteMacros",
            targets: [
                "SiteMacros",
            ]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/swiftlang/swift-syntax.git",
            from: "603.0.0"
        ),
        .package(
            url: "https://github.com/swift-lco/Primitives.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Macros.git",
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
            url: "https://github.com/swift-lco/Version.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Difference.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/References.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-dsl/DSL.git",
            branch: "master"
        ),
        .package(
            url: "https://github.com/swift-lco/Assets.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "SiteMacros",
            dependencies: [
                .product(
                    name: "Constructors",
                    package: "Constructors"
                ),
                "SiteMacrosPlugin",
            ]
        ),
        .macro(
            name: "SiteMacrosPlugin",
            dependencies: [
                .product(
                    name: "SwiftCompilerPlugin",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntax",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntaxBuilder",
                    package: "swift-syntax"
                ),
                .product(
                    name: "SwiftSyntaxMacros",
                    package: "swift-syntax"
                ),
            ]
        ),
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
                .product(
                    name: "Provenance",
                    package: "DSL"
                ),
            ]
        ),
    ],
    swiftLanguageModes: [
        .v6,
    ]
)
