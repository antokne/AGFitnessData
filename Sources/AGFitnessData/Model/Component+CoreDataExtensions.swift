//
//  Component+CoreDataExtensions.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 2/03/23.
//

import Foundation
import SwiftUI
import CoreData
import AGCore

// Component Type
public enum EnumComponentType: Int16 {
	case chain
	case jockeyWheels
	case cassette
	case chainRing
	case frontTyre
	case rearTyre
	case frontPads
	case rearPads
	case frontRotor
	case rearRotor
	case bottomBracket
	case fork
	case shock
	case dropperPost
	case sealant
	case frontBrake
	case rearBrake
	
	public func name() -> String {
		switch self {
		case .chain:
			return "Chain"
		case .jockeyWheels:
			return "Jockey Wheels"
		case .cassette:
			return "Cassette"
		case .chainRing:
			return "Chain Ring"
		case .frontTyre:
			return "Front Tyre"
		case .rearTyre:
			return "Rear Tyre"
		case .frontPads:
			return "Front Pads"
		case .rearPads:
			return "Rear Pads"
		case .frontRotor:
			return "Front Rotor"
		case .rearRotor:
			return "Rear Rotor"
		case .bottomBracket:
			return "Bottom Bracket"
		case .fork:
			return "Fork"
		case .shock:
			return "Shock"
		case .dropperPost:
			return "Dropper Post"
		case .sealant:
			return "Sealant"
		case .frontBrake:
			return "Front Brake"
		case .rearBrake:
			return "Rear Brake"

		}
	}
	
	public func subComponents() -> [ComponentSubType] {
		switch self {
		case .chain:
			return [.chainLink]
		default:
			return []
		}
	}
	
	public static func enumFrom(name: String) -> EnumComponentType? {
		
		for component in EnumComponentType.allCases {
			if name == component.name() {
				return component
			}
		}
		return nil
	}
}

extension EnumComponentType: GenericFieldTypeProtocol, CaseIterable {
	
	public static func allFields() -> [GenericFieldValue] {
		var componentFields: [GenericFieldValue] = [notSelected]
		for component in EnumComponentType.allCases {
			componentFields.append(component.field())
		}
		return componentFields
	}
	
	public func field() -> GenericFieldValue {
		GenericFieldValue(key: Int(self.rawValue), value: self.name())
	}
}

public enum ComponentSubType: Int16 {
	case chainLink
	
	func name() -> String {
		switch self {
		case .chainLink:
			return "Chain Link"
		}
	}
}

//enum ComponentTrackType: Int16, CaseIterable {
//	case distance
//	case activityTime
//	case calendarTime
//	
//	func name() -> String {
//		switch self {
//		case .distance:
//			return "Distance"
//		case .activityTime:
//			return "Activity Time"
//		case .calendarTime:
//			return "Calendar Time"
//		}
//	}
//	
//	static func enumFrom(name: String) -> ComponentTrackType? {
//		
//		for trackType in ComponentTrackType.allCases {
//			if name == trackType.name() {
//				return trackType
//			}
//		}
//		return nil
//	}
//}
//
//extension ComponentTrackType: GenericFieldTypeProtocol {
//	
//	static func allFields() -> [GenericFieldValue] {
//		var componentFields: [GenericFieldValue] = []
//		for component in ComponentTrackType.allCases {
//			componentFields.append(component.field())
//		}
//		return componentFields
//	}
//	
//	func field() -> GenericFieldValue {
//		GenericFieldValue(key: Int(self.rawValue), value: self.name())
//	}
//	
//}



public extension Component {
	
	class func sortedFetchRequest(bike: Bike? = nil) -> NSFetchRequest<Component> {
		let fetchRequest = NSFetchRequest<Component>(entityName: "Component")
		if let bike {
			fetchRequest.predicate = NSPredicate(format: "(bike == %@) AND (retired == NULL) AND parentComponent == NULL", bike)
		}
		let sortDescriptor = NSSortDescriptor(keyPath: \Component.name, ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}

	class func sortedChildFetchRequest(bike: Bike? = nil) -> NSFetchRequest<Component> {
		let fetchRequest = NSFetchRequest<Component>(entityName: "Component")
		if let bike {
			fetchRequest.predicate = NSPredicate(format: "(bike == %@) AND (retired == NULL) AND parentComponent != NULL", bike)
		}
		let sortDescriptor = NSSortDescriptor(keyPath: \Component.name, ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}
	
	class func findActiveComponent(for bike: Bike, type: EnumComponentType) -> [Component] {
		guard let components = bike.components as? Set<Component> else {
			return []
		}
		let result = components.filter({ EnumComponentType(rawValue: Int16($0.type)) == type })
		return Array(result)
	}
	
	func getTypeName() -> String? {
		if let type = EnumComponentType(rawValue: self.type),
		 parentComponent == nil {
			return type.name()
		}
		
		if let subType = ComponentSubType(rawValue: self.type),
			parentComponent != nil {
			return subType.name()
		}
		return nil
	}
	
	func getType() -> EnumComponentType? {
		EnumComponentType(rawValue: self.type)
	}

	func getSubType() -> ComponentSubType? {
		ComponentSubType(rawValue: self.type)
	}

	func getTrackType() -> ComponentRuleType? {
		ComponentRuleType(rawValue: self.trackType)
	}
	
	@discardableResult
	class func add(to bike: Bike, controller: PersistenceController = PersistenceController.shared) -> Component {
		let newComponent = Component(context: controller.container.viewContext)
		newComponent.bike = bike
		newComponent.createdAt = Date()
		return newComponent
	}
	
	@discardableResult
	func setName(name: String?) -> Component {
		if let name {
			self.name = name
		}
		return self
	}

	@discardableResult
	func setBrand(brand: String?) -> Component {
		if let brand {
			self.brand = brand}
		return self
	}

	@discardableResult
	func setModel(model: String?) -> Component {
		if let model {
			self.model = model
		}
		return self
	}

	@discardableResult
	func setType(type: EnumComponentType?) -> Component {
		if let type {
			self.type = type.rawValue
		}
		return self
	}

	@discardableResult
	func setSubType(type: ComponentSubType?) -> Component {
		if let type {
			self.type = type.rawValue
		}
		return self
	}
	
	@discardableResult
	func setDistance(distance: Double?) -> Component {
		if let distance {
			self.distance = distance
		}
		return self
	}

	@discardableResult
	func setDuration(duration: Int64?) -> Component {
		if let duration {
			self.duration = duration
		}
		return self
	}
	
	@discardableResult
	func setvalue(value: Double) -> Component {
		self.value = value
		return self
	}
	
	@discardableResult
	func addSubComponent(component: Component? = nil) -> Component {
		if let component {
			self.addToSubComponents(component)
		}
		return self
	}
	
	@discardableResult
	func removeSubComponent(component: Component? = nil) -> Component {
		if let component {
			self.removeFromSubComponents(component)
		}
		return self
	}
	
	@discardableResult
	func setParent(component: Component? = nil) -> Component {
		if let component {
			self.parentComponent = component
		}
		return self
	}
	
	@discardableResult
	func setTrackType(trackType: ComponentRuleType?) -> Component {
		if let trackType {
			self.trackType = trackType.rawValue
		}
		return self
	}
	
	func hasSubComponents() -> Bool {
		return subComponents?.count ?? 0 > 0
	}
	
	func save() {
		PersistenceController.shared.save()
	}
	
	func delete() {
		PersistenceController.shared.delete(object: self)
	}
	
	func addDistance(deltaDistance: Double) {
		self.distance += deltaDistance
		if distance < 0 {
			distance = 0
		}
		self.updatedAt = Date()
	}
	
	/// Add duration to total duration in seconds that this compoenent has been used
	/// - Parameter deltaDuration: duration in seconds to add to this component
	func addDuration(deltaDuration: Int64) {
		self.duration += deltaDuration
		if duration < 0 {
			duration = 0
		}
		self.updatedAt = Date()
	}
	
	func retire() {
		self.retired = true
		self.updatedAt = Date()
	}
	
	func getCalendarTimeDuration() -> TimeInterval {
		let createdDate: Date = createdAt ?? updatedAt ?? Date()
		let durationTimeInterval = Date().timeIntervalSinceReferenceDate - createdDate.timeIntervalSinceReferenceDate
		return durationTimeInterval
	}
	
	/// Unwraps createdAt, should not be nil but otherwise tries to use updatedAt or Now.
	/// - Returns: the created at date.
	func getCreatedAtDate() -> Date {
		createdAt ?? updatedAt ?? Date()
	}
}
