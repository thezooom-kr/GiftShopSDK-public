// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GiftShopSDK",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "GiftShopSDK", targets: ["GiftShopSDK"])
    ],
    targets: [
        .target(
            name: "GiftShopSDK",
            path: "sdk"
        )
    ]
)
