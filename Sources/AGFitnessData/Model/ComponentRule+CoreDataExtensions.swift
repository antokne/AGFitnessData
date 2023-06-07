//
//  ComponentRule+CoreDataExtensions.swift
//  Gruppo
//
//  Created by Antony Gardiner on 2/05/23.
//

import Foundation
import CoreData
import AGCore

public enum ComponentRuleType: Int16, CaseIterable {
	
	case distance		// In km
	case activityTime	// In seconds
	case calendarDate	// Specific date or if template value is a timeinterval to add to date.
	case wear			// percentage new. 100% is new. e.g. replace or service at 50%
	case useCount		// repalce when used this many times, e.g. chain link used 5 times
	
	public func name() -> String {
		switch self {
		case .distance:
			return "Distance (Km)"
		case .activityTime:
			return "Activity Time (Hrs)"
		case .calendarDate:
			return "Calendar Date"
		case .wear:
			return "Percent new (%)"
		case .useCount:
			return "Used count"
		}
	}

	public func shortName() -> String {
		switch self {
		case .distance:
			return "Distance"
		case .activityTime:
			return "Time"
		case .calendarDate:
			return "Date"
		case .wear:
			return "Wear"
		case .useCount:
			return "Count"
		}
	}
	
	public var symbol: String {
		switch self {
		case .distance:
			return "Km"
		case .activityTime:
			return "Hrs"
		case .calendarDate:
			return ""
		case .wear:
			return "%"
		case .useCount:
			return ""
		}
	}
	
	public static func enumFrom(name: String) -> ComponentRuleType? {
		
		for ruleType in ComponentRuleType.allCases {
			if name == ruleType.name() {
				return ruleType
			}
		}
		return nil
	}
}

extension ComponentRuleType: GenericFieldTypeProtocol {
	
	public static func allFields() -> [GenericFieldValue] {
		var componentFields: [GenericFieldValue] = []
		for component in ComponentRuleType.allCases {
			componentFields.append(component.field())
		}
		return componentFields
	}
	
	public func field() -> GenericFieldValue {
		GenericFieldValue(key: Int(self.rawValue), value: self.name())
	}
}

public extension ComponentRule {
	
	class func sortedFetchRequest(componentType: ComponentType? = nil, template: Bool? = nil) -> NSFetchRequest<ComponentRule> {
		let fetchRequest = NSFetchRequest<ComponentRule>(entityName: ComponentRule.className)
		var subPredicates: [NSPredicate] = []
		if let componentType {
			subPredicates.append(inPredicate(for: componentType, in: \ComponentRule.componentTypes))
		}
		
		if let template {
			subPredicates.append(\ComponentRule.template == template)
		}
		
		if subPredicates.count > 0 {
			fetchRequest.predicate = NSCompoundPredicate(type: .and, subpredicates: subPredicates)
		}
		
		let sortDescriptor = NSSortDescriptor(keyPath: \ComponentType.name, ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}

	@discardableResult
	class func add(name: String,
				   message: String? = nil,
				   template: Bool = false,
				   _ persistenceController: PersistenceController = PersistenceController.shared) -> ComponentRule {
		let newComponentRule = ComponentRule(context: persistenceController.container.viewContext)
		newComponentRule.name = name
		newComponentRule.template = template
		newComponentRule.createdAt = Date()
		return newComponentRule
	}
	
	func delete(_ persistenceController: PersistenceController = PersistenceController.shared) {
		persistenceController.delete(object: self)
	}
	
	func save(_ persistenceController: PersistenceController = PersistenceController.shared) {
		persistenceController.save()
	}
	
	@discardableResult
	func setType(type: ComponentRuleType, value: Int64) -> ComponentRule {
		self.type = type.rawValue
		self.updatedAt = Date()
		
		switch type {
		case .distance, .wear, .activityTime, .useCount:
			self.ruleValue = value
		case .calendarDate:
			if template {
				self.ruleValue = value
			}
			else {
				self.ruleDate = Date().addingTimeInterval(TimeInterval(value))
			}
		}
		return self
	}
	
	@discardableResult
	func setNotificationMessage(message: String?) -> ComponentRule {
		self.notificationMessage = message
		self.updatedAt = Date()
		return self
	}
	
	@discardableResult
	func add(componentType: ComponentType) -> ComponentRule {
		self.addToComponentTypes(componentType)
		return self
	}

	@discardableResult
	func remove(componentType: ComponentType) -> ComponentRule {
		self.removeFromComponentTypes(componentType)
		return self
	}
	
	var ruleType: ComponentRuleType? {
		get {
			ComponentRuleType(rawValue: type)
		}
		set {
			type = newValue?.rawValue ?? 0
		}
	}
	
	static func insertTemplateComponentRules(_ persistenceController: PersistenceController = PersistenceController.shared) -> Bool {
		
		persistenceController.container.viewContext.performAndWait {
			
			guard let sealantComponentType = ComponentType.get(by: 14) else { return false }
			ComponentRule.add(name: "Top up sealant", template: true, persistenceController)
			.setType(type: .calendarDate, value: Int64(TimeInterval.timeInterval(months: 6)))
				.add(componentType: sealantComponentType)
			
			guard let chainComponentType = ComponentType.get(by: 0) else { return false }
			ComponentRule.add(name: "Wax", template: true, persistenceController)
				.setType(type: .distance, value: 500)
				.add(componentType: chainComponentType)
			ComponentRule.add(name: "Replace", template: true, persistenceController)
				.setType(type: .wear, value: 50)
				.add(componentType: chainComponentType)
			
			guard let shockComponentType = ComponentType.get(by: 11) else { return false }
			ComponentRule.add(name: "Service shock", template: true, persistenceController)
				.setType(type: .activityTime, value: 1800000) // 500 hours
				.add(componentType: shockComponentType)
			
			guard let frontBrakeComponentType = ComponentType.get(by: 15) else { return false }
			guard let rearBrakeComponentType = ComponentType.get(by: 16) else { return false }
			ComponentRule.add(name: "Bleed brake", template: true, persistenceController)
			.setType(type: .calendarDate, value: Int64(TimeInterval.timeInterval(years: 2)))
				.add(componentType: frontBrakeComponentType)
				.add(componentType: rearBrakeComponentType)
			
			
			guard let tyreComponentType = ComponentType.get(by: 7) else { return false }
			ComponentRule.add(name: "Replace", template: true, persistenceController)
				.setType(type: .wear, value: 25)
				.add(componentType: tyreComponentType)
			
			ComponentRule.add(name: "Check Pressure", template: true, persistenceController)
			.setType(type: .calendarDate, value: Int64(TimeInterval.timeInterval(days: 5)))
				.add(componentType: tyreComponentType)
			
			guard let chainLinkComponentType = ComponentType.get(by: 9) else { return false }
			ComponentRule.add(name: "Replace", template: true, persistenceController)
				.setType(type: .useCount, value: 5)
				.add(componentType: chainLinkComponentType)
			
			return true
		}
	}
}


public extension TimeInterval {

	static func timeInterval(days: Int) -> TimeInterval {
		return Double(days) * 60.0 * 60.0 * 24.0
	}
		
	static func timeInterval(months: Int) -> TimeInterval {
		return Double(months) * 60.0 * 60.0 * 24.0 * 30.42
	}
	
	static func timeInterval(years: Int) -> TimeInterval {
		Double(years) * 24.0 * 60.0 * 60.0 * 365.25
	}
	
	static func daysFrom(timeInterval: TimeInterval) -> Int {
		Int((timeInterval / 60.0 / 60.0 / 24.0).rounded())
	}

	static func monthsFrom(timeInterval: TimeInterval) -> Int {
		Int((timeInterval / 60.0 / 60.0 / 24.0 / 30.42).rounded())
	}

	static func yearsFrom(timeInterval: TimeInterval) -> Int {
		Int((timeInterval / 60.0 / 60.0 / 24.0 / 365.25).rounded())
	}

}
