// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AGFitnessData",
	platforms: [
		.iOS(.v16),
		.tvOS(.v16),
		.macOS(.v10_14),
	],
	products: [
		// Products define the executables and libraries a package produces, and make them visible to other packages.
		.library(
			name: "AGFitnessData",
			targets: ["AGFitnessData"]),
	],
	dependencies: [
		// Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/antokne/AGCore", branch: "develop"),
		.package(url: "https://github.com/antokne/AGFitCore", branch: "develop"),
		.package(url: "https://github.com/antokne/swift-strava", branch: "master"),
		.package(url: "https://github.com/apple/swift-log", .upToNextMajor(from: "1.0.0")),
	],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages this package depends on.
		.target(
			name: "AGFitnessData",
			dependencies: [.product(name: "AGCore", package: "AGCore"),
						   .product(name: "AGFitCore", package: "AGFitCore"),
						   .product(name: "SwiftStrava", package: "swift-strava"),
						   .product(name: "Logging", package: "swift-log")],
			resources: [
				.process("Resources"),
			]),
		.testTarget(
			name: "AGFitnessDataTests",
			dependencies: ["AGFitnessData"]),
	]
)
