import PackageDescription

let package = Package(
  name: "PinCodeInputView",
  products: [
    .library(name: "PinCodeInputView", targets: ["PinCodeInputView"]),
  ],
  dependencies: [
    .package(url: "https://github.com/sunlyear/PinCodeInputView", .upToNextMajor(from: "2.0.0")),
  ],
  targets: [
    .target(name: "PinCodeInputView", dependencies: []),
  ]
)