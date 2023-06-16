//
//  Activity+CoreDataProperties.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 16/12/22.
//
//

import Foundation
import CoreData
import FitDataProtocol
import AntMessageProtocol
import SwiftStrava

extension Activity {
	
	@nonobjc public class func fetchRequest() -> NSFetchRequest<Activity> {
		return NSFetchRequest<Activity>(entityName: "Activity")
	}

	@NSManaged public var name: String?
	@NSManaged public var avgPowerW: Int16
	@NSManaged public var avgSpeedMPS: Double
	@NSManaged public var calories: Int32
	@NSManaged public var distanceM: Double
	@NSManaged public var durationS: Int64
	@NSManaged public var elevationM: Int32
	@NSManaged public var fileName: String?
	@NSManaged public var polyline: String?
	@NSManaged public var startDate: Date?
	@NSManaged public var subSport: Int16
	@NSManaged public var bike: Bike?
	@NSManaged public var sourceId: String?
	@NSManaged public var source: Int16

	
	private static var dateFormatter = DateFormatter()
	
	@objc public var startOfWeek: String? {
	
		Activity.dateFormatter.dateFormat = "dd MMM yyy"
		guard let weekStart = self.startDate?.startOfWeek else {
			return "Unknown"
		}
		return Activity.dateFormatter.string(from: weekStart)
	}

}

extension Activity: Identifiable { }

extension Activity: BikeRelationshipProtocol { }


public extension Activity {
	
	var sourceType: BikeSource {
		BikeSource(rawValue: source) ?? .unknown
	}
	
	func delete(context: NSManagedObjectContext) {
				
		if let bike = self.bike {
			bike.removeActivityFromComponents(activity: self)
		}
		
		context.delete(self)
	}
		
	func getActivityCountOlder() -> Int {
		guard let date = self.startDate as? NSDate else {
			return Int.max
		}
		let fetchRequest = NSFetchRequest<Activity>(entityName: "Activity")
		fetchRequest.predicate = NSPredicate(format: "startDate < %@", date)
		do {
			let result  = try fetchRequest.execute()
			return result.count
		} catch {
			print("\(error)")
		}
		return Int.max
	}
	
	/// Clear all activities locally... for debugging
	static func resetActivities() {
		
		let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Activity")
		let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
		
		do {
			try PersistenceController.shared.container.persistentStoreCoordinator.execute(deleteRequest, with: PersistenceController.shared.container.viewContext)
			PersistenceController.shared.save()
		} catch {
			print("\(error)")
		}
	}
}

public extension Activity {
	
	func set(from session: SessionMessage) {
		
		
		self.name = session.sport?.stringValue ?? "Activity"
		self.startDate = session.startTime?.recordDate
		if let distanceM = session.totalDistance?.value {
			self.distanceM = distanceM
		}
		if let durationS = session.totalTimerTime?.value {
			self.durationS = Int64(durationS)
		}
		if let avgPowerW = session.averagePower?.value {
			self.avgPowerW = Int16(avgPowerW)
		}
		if let avgSpeedMPS = session.averageSpeed?.value {
			self.avgSpeedMPS = avgSpeedMPS
		}
		if let elevationM = session.totalAscent?.value {
			self.elevationM = Int32(elevationM)
		}
		if let calories = session.totalCalories?.value {
			self.calories = Int32(calories)
		}
		if let subSport = session.subSport?.rawValue {
			self.subSport = Int16(subSport)
		}
	}
	
	func set(from activity : SummaryActivity) {
		
		self.name = activity.name
		self.startDate = activity.startDate
		if let distanceM = activity.distance {
			self.distanceM = Double(distanceM)
		}
		if let durationS = activity.movingTime {
			self.durationS = Int64(durationS)
		}
		if let avgPowerW = activity.averageWatts {
			self.avgPowerW = Int16(avgPowerW)
		}
		if let avgSpeedMPS = activity.averageSpeed {
			self.avgSpeedMPS = Double(avgSpeedMPS)
		}
		if let elevationM = activity.totalElevationGain {
			self.elevationM = Int32(elevationM)
		}
		if let calories = activity.kilojoules {
			self.calories = Int32(calories / 4.184)
		}
		if let sportType = activity.sportType {
			self.subSport = Int16(sportType.subSport.rawValue)
		}
		
		self.source = BikeSource.strava.rawValue
		if let activityId = activity._id {
			self.sourceId = String(activityId)
		}
	}
	
	func set(from activity : DetailedActivity) {
		
		self.name = activity.name
		self.startDate = activity.startDate
		if let distanceM = activity.distance {
			self.distanceM = Double(distanceM)
		}
		if let durationS = activity.movingTime {
			self.durationS = Int64(durationS)
		}
		if let avgPowerW = activity.averageWatts {
			self.avgPowerW = Int16(avgPowerW)
		}
		if let avgSpeedMPS = activity.averageSpeed {
			self.avgSpeedMPS = Double(avgSpeedMPS)
		}
		if let elevationM = activity.totalElevationGain {
			self.elevationM = Int32(elevationM)
		}
		if let calories = activity.kilojoules {
			self.calories = Int32(calories / 4.184)
		}
		if let sportType = activity.sportType {
			self.subSport = Int16(sportType.subSport.rawValue)
		}
		
		self.source = BikeSource.strava.rawValue
		if let activityId = activity._id {
			self.sourceId = String(activityId)
		}
	}
	
	func numberOfRows() -> Int {
		var rowCount = 0;
		if self.distanceM != 0 {
			rowCount += 1
		}
		if self.durationS != 0 {
			rowCount += 1
		}
		if self.avgPowerW != 0 {
			rowCount += 1
		}
		if self.avgSpeedMPS != 0 {
			rowCount += 1
		}
		if self.elevationM != 0 {
			rowCount += 1
		}
		if self.calories != 0 {
			rowCount += 1
		}
		return rowCount
	}
	
	func imageNameForSubSport() -> String {
		var imageName = "figure.outdoor.cycle"
		let subSport = SubSport(rawValue: UInt8(self.subSport))
		switch subSport {
		case .indoorCycling:
			imageName = "figure.indoor.cycle"
		case .street:
			imageName = "figure.run"
		default:
			break
		}
		return imageName
	}
	
}
