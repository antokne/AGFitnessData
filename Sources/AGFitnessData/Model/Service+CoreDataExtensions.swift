//
//  Service+CoreDataExtensions.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 2/03/23.
//

import Foundation
import CoreData
import AGCore

public enum ServiceType: Int16 {
	case wax
	case degrease
	case measure
	case wash
	case oil
	
	public func name() -> String {
		switch self {
		case .wax:
			return "Wax"
		case .degrease:
			return "Degrease"
		case .measure:
			return "Measure"
		case .wash:
			return "Wash"
		case .oil:
			return "Oil"
		}
	}
	
	public static func enumFrom(name: String) -> ServiceType? {
		for service in ServiceType.allCases {
			if name == service.name() {
				return service
			}
		}
		return nil
	}
}

extension ServiceType: GenericFieldTypeProtocol, CaseIterable {
	
	public static func allFields() -> [GenericFieldValue] {
		var serviceFields: [GenericFieldValue] = [notSelected]
		for service in ServiceType.allCases {
			serviceFields.append(service.field())
		}
		return serviceFields
	}
	
	public func field() -> GenericFieldValue {
		GenericFieldValue(key: Int(self.rawValue), value: self.name())
	}
}

public extension Service {
	
	class func sortedFetchRequest(component: Component) -> NSFetchRequest<Service> {		
		let fetchRequest = NSFetchRequest<Service>(entityName: "Service")
			fetchRequest.predicate = NSPredicate(format: "(components CONTAINS %@)", component)
		let sortDescriptor = NSSortDescriptor(keyPath: \Service.createdAt, ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}
	
	func getTypeName() -> String? {
		return ServiceType(rawValue: self.type)?.name()
	}
	
	func getType() -> ServiceType? {
		ServiceType(rawValue: self.type)
	}

	@discardableResult
	class func new() -> Service {
		let newSerivce = Service(context: PersistenceController.shared.container.viewContext)
		newSerivce.createdAt = Date()
		return newSerivce
	}
	
	@discardableResult
	func add(to component: Component) -> Service {
		addToComponents(component)
		return self
	}

	@discardableResult
	func setDate(date: Date?) -> Service {
		if let date {
			self.createdAt = date
		}
		return self
	}
	
	@discardableResult
	func setType(type: ServiceType?) -> Service {
		if let type {
			self.type = type.rawValue
		}
		return self
	}
	
	@discardableResult
	func setNote(note: String?) -> Service {
		if let note {
			self.note = note
		}
		return self
	}

	@discardableResult
	
	/// Flag to inidcate if the compoent was removed as part of the serice.
	/// - Parameter removed: true if removed
	/// - Returns: the updated service
	func setRemoved(removed: Bool?) -> Service {
		if let removed {
			self.removed = removed
		}
		return self
	}
	
	@discardableResult
	/// Sets the value of the service, e.g. for a measurement this could be the 100% wear.
	/// - Parameter value: value to use
	/// - Returns: the service
	func setValue(value: Double?) -> Service {
		if let value {
			self.value = value
		}
		return self
	}
	
	func save() {
		PersistenceController.shared.save()
	}
	
	func delete() {
		PersistenceController.shared.delete(object: self)
	}
}
