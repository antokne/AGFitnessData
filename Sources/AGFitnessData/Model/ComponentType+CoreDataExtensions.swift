//
//  EnumComponentType+CoreDataExtensions.swift
//  Gruppo
//
//  Created by Antony Gardiner on 19/04/23.
//

import Foundation
import CoreData

public extension ComponentType {
	
	class func sortedFetchRequest(exclude: ComponentType? = nil) -> NSFetchRequest<ComponentType> {
		let fetchRequest = NSFetchRequest<ComponentType>(entityName: "ComponentType")
		if let exclude {
			fetchRequest.predicate =
			NSCompoundPredicate(type: .and,
								subpredicates: [
									// we do not want to show the parent else we will create an unwanted loop between itself
									NSPredicate(format: "id != %d", exclude.id),
									
									// we do not want to show the parent else we will create an unwanted loop between itself
									NSPredicate(format: "!(self IN %@.childComponentTypes)", exclude),
									
									// nor do we want to allow a circular loop hence
									// exclude current where it has the current in it's children or parents already.
									NSPredicate(format: "!(self IN %@.validParentComponentTypes)", exclude)
								])
		}
		let sortDescriptor = NSSortDescriptor(keyPath: \ComponentType.name, ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}
	
	class func sortedChildrenFetchRequest(parent: ComponentType?) -> NSFetchRequest<ComponentType> {
		let fetchRequest = NSFetchRequest<ComponentType>(entityName: "ComponentType")
	
		if let parent {
			fetchRequest.predicate = NSPredicate(format: "%@ in validParentComponentTypes", parent)
		}
		let sortDescriptor = NSSortDescriptor(keyPath: \ComponentType.name, ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}
	
	/// Get the next id to insert value for
	/// - Parameter persistenceController: option controller
	/// - Returns: the new value to insert.
	class func getNextId(_ persistenceController: PersistenceController = PersistenceController.shared) -> Int {
		let fetchRequest = ComponentType.sortedFetchRequest()
		let sortDescriptor = NSSortDescriptor(keyPath: \ComponentType.id, ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]
		if let result = try? persistenceController.container.viewContext.fetch(fetchRequest).first {
			return Int(result.id) + 1
		}
		return 0
	}
	
	@discardableResult
	class func add(id: Int, name: String,
				   _ persistenceController: PersistenceController = PersistenceController.shared) -> ComponentType {
		let newComponentType = ComponentType(context: persistenceController.container.viewContext)
		newComponentType.id = Int16(id)
		newComponentType.name = name
		newComponentType.createdAt = Date()
		return newComponentType
	}
	
	@discardableResult
	func addValidParent(parent: ComponentType) -> ComponentType {
		self.addToValidParentComponentTypes(parent)
		return self
	}
	
	func delete(_ persistenceController: PersistenceController = PersistenceController.shared) {
		persistenceController.delete(object: self)
	}

	func save(_ persistenceController: PersistenceController = PersistenceController.shared) {
		persistenceController.save()
	}
	
	static func get(by id: Int, _ persistenceController: PersistenceController = PersistenceController.shared) -> ComponentType? {
		let fetchRequest = NSFetchRequest<ComponentType>(entityName: "ComponentType")
		fetchRequest.predicate = NSPredicate(format: "id = %d", id)
		if let result = try? persistenceController.container.viewContext.fetch(fetchRequest).first {
			return result
		}
		return nil
	}
	
	static func insertDefaultComponentTypes(_ persistenceController: PersistenceController = PersistenceController.shared) -> Bool {
		
		persistenceController.container.viewContext.performAndWait {
		
			let chain = ComponentType.add(id: 0, name: "Chain", persistenceController)
			ComponentType.add(id: 1, name: "Jockey Wheels", persistenceController)
			ComponentType.add(id: 2, name: "Chain Ring", persistenceController)
			
			let frontWheel = ComponentType.add(id: 4, name: "Front Wheel", persistenceController)
			let rearWheel = ComponentType.add(id: 5, name: "Rear Wheel", persistenceController)
			
			// can be added to a wheel
			ComponentType.add(id: 6, name: "Cassette", persistenceController)
				.addValidParent(parent: rearWheel)
			
			let tyre = ComponentType.add(id: 7, name: "Tyre", persistenceController)
				.addValidParent(parent: frontWheel)
				.addValidParent(parent: rearWheel)
			
			ComponentType.add(id: 8, name: "Disc rotor", persistenceController)
				.addValidParent(parent: frontWheel)
				.addValidParent(parent: rearWheel)
			
			ComponentType.add(id: 9, name: "Chain link", persistenceController)
				.addValidParent(parent: chain)
			
			ComponentType.add(id: 10, name: "Bottom Bracket", persistenceController)
			ComponentType.add(id: 11, name: "Shock", persistenceController)
			ComponentType.add(id: 12, name: "Fork", persistenceController)
			ComponentType.add(id: 13, name: "Dropper post", persistenceController)
			
			ComponentType.add(id: 14, name: "Sealant", persistenceController)
				.addValidParent(parent: tyre)
			
			let frontBrake = ComponentType.add(id: 15, name: "Front Brake", persistenceController)
			let rearBrake = ComponentType.add(id: 16, name: "Rear Brake", persistenceController)
			
			ComponentType.add(id: 3, name: "Brake Pads", persistenceController)
				.addValidParent(parent: frontBrake)
				.addValidParent(parent: rearBrake)
			
		}
		
		return true
	}
	
}
