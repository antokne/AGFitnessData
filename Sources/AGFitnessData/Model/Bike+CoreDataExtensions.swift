//
//  Bike+CoreDataExtensions.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 18/01/23.
//

import Foundation
import SwiftUI
import SwiftStrava
import CoreData

/// Source that the bike details has come from
public enum BikeSource: Int16 {
	case strava = 0
	case unknown = 1
}

/// This maps to strava values currently
public enum BikeFrameType: Int16 {
	case mountainBike = 1
	case crossBike = 2
	case roadBike = 3
	case ttBike = 4
	case gravelBike = 5
	
	func name() -> String {
		switch self {
		case .roadBike:
			return "Road Bike"
		case .mountainBike:
			return "MTB Bike"
		case .ttBike:
			return "TT Bike"
		case .crossBike:
			return "Cross Bike"
		case .gravelBike:
			return "Gravel Bike"
		}
	}
}

public extension Bike {
	
	class func sortedFetchRequest() -> NSFetchRequest<Bike> {
		let fetchRequest = NSFetchRequest<Bike>(entityName: "Bike")
		let sortDescriptor = NSSortDescriptor(keyPath: \Bike.name, ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}
	
	@discardableResult
	func setModel(model: String) -> Bike {
		self.model = model
		return self
	}
	
	@discardableResult
	func setSource(source: BikeSource) -> Bike {
		self.source = source.rawValue
		return self
	}
	
	@discardableResult
	func setSourceId(sourceId: String) -> Bike {
		self.sourceId = sourceId
		return self
	}
	
	func getFrameTypeName() -> String? {
		return BikeFrameType(rawValue: self.frameType)?.name()
	}
	
	/// Go through bike values and see if it has changed from remote (strava)
	/// - Parameter bike: SummaryGear of bike from strava
	/// - Returns: true if udpated.
	func updateBike(bike: DetailedGear) -> Bool {
		
		var updated = false
		
		if let name = bike.name,
		   self.name != name {
			self.name = name
			updated = true
		}
		
//		if self.distance == 2697183.0 {
//			self.distance = 2697183.0 - 49900
//		}
		
		if let newDistance = bike.distance,
		   Double(newDistance) != self.distance {
			
			// if there is a difference update all the components on this bike
			// it could be negative if the you changed the bike the activity was saved to
			// strava with.
			let deltaDistance = Double(newDistance) - self.distance
			if let components = self.components as? Set<Component> {
				
				// update components...
				for component in components {
					component.addDistance(deltaDistance: deltaDistance)
				}
			}
			
			self.distance = Double(newDistance)
			updated = true
		}
		
		if let brand = bike.brandName,
		   self.brand != brand {
			self.brand = brand
			updated = true
		}
		
		if let model = bike.modelName,
		   self.model != model {
			self.model = model
			updated = true
		}
		
		if let stravaFrameType = bike.frameType,
		   self.frameType != stravaFrameType {
			self.frameType = Int16(stravaFrameType)
			updated = true
		}
		
		// if changed update the timestamp for sorting.
		if updated {
			self.timestamp = Date()
		}
		
		return updated
	}
	
	func updateBike(for activity: Activity) {
		
		// get activity duration
		let durationS = activity.durationS
		
		// up date all components
		guard let components = self.components as? Set<Component> else {
			return
		}
		
		for component in components {
			component.addDuration(deltaDuration: durationS)
			
			if activity.sourceType == .unknown {
				component.addDistance(deltaDistance: activity.distanceM)
			}
		}
		
	}
	
	func removeActivityFromComponents(activity: Activity) {
		
		guard let components = components as? Set<Component> else {
			return
		}
		
		for component in components {
			// subtracked duration from the component.
			// only duration because distance is managed via bike distance from Strava.
			component.addDuration(deltaDuration: -activity.durationS)
			
			if activity.sourceType == .unknown {
				component.addDistance(deltaDistance: -activity.distanceM)
			}
		}
	}
	
	static func findBike(by sourceId: String, _ context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) -> Bike? {
		
		let request: NSFetchRequest<Bike> = Bike.fetchRequest()
		request.predicate = NSPredicate(format: "sourceId = %@", sourceId)
		
		if let result = try? context.fetch(request) {
			return result.first
		}
		
		// not found or error
		return nil
	}
		
	@discardableResult
	static func add(name: String, date: Date) -> Bike {
		
		let viewContext = PersistenceController.shared.container.viewContext
		let newBike = Bike(context: viewContext)
		
		newBike.name = name
		newBike.timestamp = date
		PersistenceController.shared.save()
		return newBike
	}
	
}
