//
//  File.swift
//  
//
//  Created by Antony Gardiner on 27/06/23.
//

import Foundation
import CoreData

public enum ActivityShareStatusSiteType: Int16 {
	case myBikeTraffic = 0
	
	var name: String {
		switch self {
		case .myBikeTraffic:
			return "MyBikeTraffic"
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
}
