//
//  ActivityShareStatusTests.swift
//  
//
//  Created by Antony Gardiner on 27/06/23.
//

import XCTest
@testable import AGFitnessData

final class ActivityShareStatusTests: XCTestCase {
	
	override func setUpWithError() throws {
	}
	
	override func tearDownWithError() throws {
	}
	
	func testProperties() throws {
		
		let persistence = PersistenceController.preview
		let context = persistence.container.viewContext
		
		let shareStatus = ActivityShareStatus(context: context)

		shareStatus
			.setShareSiteId(id: "erere")
			.setShareSiteType(site: .myBikeTraffic)
			.setStatusType(status: .completed)
		
		XCTAssertEqual(shareStatus.shareSiteId, "erere")
		XCTAssertEqual(shareStatus.shareSiteType, .myBikeTraffic)
		XCTAssertEqual(shareStatus.shareStatusType, .completed)

		
	}
	
	func testLinksToActivity() throws {
		
		let persistence = PersistenceController.preview
		let context = persistence.container.viewContext
		
		let activity = Activity(context: context)
		
		let shareStatus = ActivityShareStatus(context: context)
		shareStatus.activity = activity
		shareStatus.setShareSiteId(id: "erere")

		let shareStatus2 = ActivityShareStatus(context: context)
		shareStatus2.activity = activity
		shareStatus2.setShareSiteId(id: "dfadf")
		
		XCTAssertTrue(((activity.activityShareStatus?.contains(where: { $0.shareSiteId == "erere" })) != nil))
		XCTAssertTrue(((activity.activityShareStatus?.contains(where: { $0.shareSiteId == "dfadf" })) != nil))
		
		shareStatus.activity = nil
		shareStatus2.activity = nil
		
		XCTAssertTrue(activity.activityShareStatus?.count == 0)

	}
	
	func testLinksFromShareSiteToActivity() throws {
		
		let persistence = PersistenceController.preview
		let context = persistence.container.viewContext
		
		let activity = Activity(context: context)
		
		let shareStatus = ActivityShareStatus(context: context)
		shareStatus.setShareSiteId(id: "erere")
		activity.addToShareStatus(shareStatus)
		
		let shareStatus2 = ActivityShareStatus(context: context)
		shareStatus2.setShareSiteId(id: "dfadf")
		activity.addToShareStatus(shareStatus2)

		XCTAssertNotNil(activity.activityShareStatus?.contains(where: { $0.shareSiteId == "erere" }))
		XCTAssertNotNil(activity.activityShareStatus?.contains(where: { $0.shareSiteId == "dfadf" }))
		
		activity.removeFromShareStatus(shareStatus)
		activity.removeFromShareStatus(shareStatus2)

		XCTAssertTrue(activity.activityShareStatus?.count == 0)

	}
}
