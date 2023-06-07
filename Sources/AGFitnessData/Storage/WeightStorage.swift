//
//  WeightStorage.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 25/07/22.
//

import Foundation
import CoreData
import Combine

public class WeightStorage: NSObject, ObservableObject {
	
	let viewContext = PersistenceController.shared.container.viewContext
	public var weights = CurrentValueSubject<[Weight], Never>([])
	private let weightFetchController:NSFetchedResultsController<Weight>
	
	// SINGELTON INSTANCE
	public static let shared: WeightStorage = WeightStorage()
	
	private override init() {
		let fetchRequest = Weight.fetchRequest()
		let sortDescriptor = NSSortDescriptor(keyPath: \Weight.timestamp, ascending: false)
		fetchRequest.sortDescriptors = [sortDescriptor]
		weightFetchController = NSFetchedResultsController(
			fetchRequest: fetchRequest,
			managedObjectContext: viewContext,
			sectionNameKeyPath: nil, cacheName: nil)
		
		super.init()
		weightFetchController.delegate = self
		do
		{
			try weightFetchController.performFetch()
			weights.value = weightFetchController.fetchedObjects ?? []
		} catch {
			NSLog( "Error: could not fetch objects")
		}
	}
	
	public func add(weight: Double, date: Date) {
		let newWeight = Weight(context: viewContext)
		newWeight.timestamp = date
		newWeight.weight = NSDecimalNumber(value: weight)
		
		do {
			try viewContext.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	public func delete(weight: Weight) {
		viewContext.delete(weight)
		
		do {
			try viewContext.save()
		} catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
}
						
extension WeightStorage: NSFetchedResultsControllerDelegate {
	public func controllerDidChangeContent(_ controller:
										   NSFetchedResultsController<NSFetchRequestResult>){
		guard let weights = controller.fetchedObjects as? [Weight] else { return }
		self.weights.value = weights
	}
	
}
