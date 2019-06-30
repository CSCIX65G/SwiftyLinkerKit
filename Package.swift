// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SwiftyLinkerKit",
    products: [
      .library(name: "SwiftyLinkerKit", targets: [ "SwiftyLinkerKit" ])
    ],
    dependencies: [
        .package(url: "https://github.com/uraimo/SwiftyGPIO.git", "1.1.2"),
        .package(url: "https://github.com/CSCIX65G/SwiftyTM1637.git", .branch("swift5"))
    ],
    targets: [
        .target(
            name: "SwiftyLinkerKit",
            dependencies: [ "SwiftyTM1637", "SwiftyGPIO" ]),
        .target(
            name: "clock",
            dependencies: [ "SwiftyLinkerKit" ]),
    ]
)
