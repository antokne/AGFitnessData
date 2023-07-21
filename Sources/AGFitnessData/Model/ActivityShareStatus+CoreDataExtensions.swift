//
//  File.swift
//  
//
//  Created by Antony Gardiner on 27/06/23.
//

import Foundation
import CoreData
import AGCore

public enum ActivityShareStatusSiteType: Int16 {
	case myBikeTraffic = 0
	
	public var name: String {
		switch self {
		case .myBikeTraffic:
			return "MyBikeTraffic.com"
		}
	}
	
	public var viewUrl: URL {
		switch self {
		case .myBikeTraffic:
			return URL(string: "https://www.mybiketraffic.com/rides/view")!
		}
	}
}

public enum ActivityShareStatusType: Int16 {
	case notShared = 0
	case inProgress = 1
	case completed = 2
	case failed = 3
}

public extension ActivityShareStatus {
	
	var shareSiteType: ActivityShareStatusSiteType? {
		ActivityShareStatusSiteType(rawValue: shareSite)
	}
	
	@discardableResult
	func setShareSiteType(site: ActivityShareStatusSiteType) -> ActivityShareStatus {
		shareSite = site.rawValue
		return self
	}
	
	@discardableResult
	func setShareSiteId(id: String) -> ActivityShareStatus {
		shareSiteId = id
		return self
	}
	
	var shareStatusType: ActivityShareStatusType? {
		ActivityShareStatusType(rawValue: shareStatus)
	}
	
	@discardableResult
	func setStatusType(status: ActivityShareStatusType) -> ActivityShareStatus {
		shareStatus = status.rawValue
		return self
	}
	
	/// Find all share status' that have not completed for some reason
	/// - Returns: all share status in progress
	class func findInprogressShareStatuses(_ context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) throws -> [ActivityShareStatus] {
		let fetchRequest = NSFetchRequest<ActivityShareStatus>(entityName: ActivityShareStatus.className)
		var subPredicates: [NSPredicate] = []
		subPredicates.append(\ActivityShareStatus.shareStatus == ActivityShareStatusType.inProgress.rawValue)
		if subPredicates.count > 0 {
			fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicates)
		}
		
		return try context.fetch(fetchRequest)
	}
}

extension ActivityShareStatus: Comparable {
	
	public static func < (lhs: ActivityShareStatus, rhs: ActivityShareStatus) -> Bool {
		lhs.shareSiteType?.rawValue ?? 0 < rhs.shareSiteType?.rawValue ?? 0
	}
	
}
