//
//  ActivityStorageTests.swift
//  
//
//  Created by Antony Gardiner on 9/06/23.
//

import XCTest
@testable import AGFitnessData

final class ActivityStorageTests: XCTestCase {
	
	override func setUpWithError() throws {
	}
	
	override func tearDownWithError() throws {
	}
	
	func testActivityFolder() throws {
		
		
		var url = try XCTUnwrap(ActivityStorage.activitiesDirectoryURL)
		XCTAssertTrue(url.path.hasSuffix("Documents/activities"))
		
		ActivityStorage.setDefault(folder: "")
		
		url = try XCTUnwrap(ActivityStorage.activitiesDirectoryURL)
		XCTAssertTrue(url.path.hasSuffix("Documents"))
		
	}
	
	
	
}
