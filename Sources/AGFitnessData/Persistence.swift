//
//  Persistence.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 25/07/22.
//

import CoreData

public struct PersistenceController {
	public static let shared = PersistenceController()
	
	public static let preview: PersistenceController = {
		let result = PersistenceController(inMemory: true)
		let viewContext = result.container.viewContext
		for _ in 0..<10 {
			let newWeight = Weight(context: viewContext)
			newWeight.timestamp = Date()
		}
		do {
			try viewContext.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
		return result
	}()
	
	public let container: NSPersistentCloudKitContainer
	
	init(inMemory: Bool = false) {
		
		guard let modelURL = Bundle.module.url(forResource:"DataModel", withExtension: "momd") else {
			fatalError("No model file!")
		}
		guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
			fatalError("No Model!")
		}
		
		container = NSPersistentCloudKitContainer(name: "DataModel", managedObjectModel: model)
		if inMemory {
			container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
		}
		container.loadPersistentStores(completionHandler: { (storeDescription, error) in
			if let error = error as NSError? {
				// Replace this implementation with code to handle the error appropriately.
				// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
				
				/*
				 Typical reasons for an error here include:
				 * The parent directory does not exist, cannot be created, or disallows writing.
				 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
				 * The device is out of space.
				 * The store could not be migrated to the current model version.
				 Check the error message to determine what the actual problem was.
				 */
				fatalError("Unresolved error \(error), \(error.userInfo)")
			}
		})
		container.viewContext.automaticallyMergesChangesFromParent = true
	}
	
	public func save() {
		let context = container.viewContext
		
		if context.hasChanges {
			do {
				try context.save()
			} catch {
				// Show some error here
			}
		}
	}
	
	public func delete(object: NSManagedObject) {
		let context = container.viewContext
		context.delete(object)
		do {
			try context.save()
		}
		catch {
			
		}
	}

	public func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
		container.performBackgroundTask(block)
	}
	
	public func performInBackground(_ block: @escaping (NSManagedObjectContext) -> Void) async {
		await container.performBackgroundSaveTask(block)
	}

}

public extension NSPersistentContainer {
	func performBackgroundSaveTask(_ block: @escaping (NSManagedObjectContext) -> Void) async {
		await performBackgroundTask { (context: NSManagedObjectContext) in
			block(context)
			try? context.save()
		}
	}
}
