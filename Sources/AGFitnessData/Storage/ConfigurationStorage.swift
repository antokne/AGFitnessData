//
//  ConfigurationStorage.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 28/07/22.
//

import Foundation

import CoreData
import Combine

public class ConfigurationStorage: NSObject, ObservableObject {
	
	let viewContext = PersistenceController.shared.container.viewContext
	var configuration: Configuration?
	
	// SINGELTON INSTANCE
	public static let shared: ConfigurationStorage = ConfigurationStorage()
	
	public var goalWeight = CurrentValueSubject<NSDecimalNumber, Never>(0)
	
	private override init() {
		super.init()
		configuration = load()
		
		goalWeight.value = configuration?.goalWeight ?? 0
	}
	
	public func load() -> Configuration? {
			
		let fetchRequest = Configuration.fetchRequest()
		do
		{
			let items = try viewContext.fetch(fetchRequest)
			if items.count == 0 {
				configuration = Configuration(context: viewContext)
			}
			else {
				configuration = items.first!
			}
		}
		catch {
			fatalError("failed to get configuration \(error)")
		}
		return configuration
	}
	
	public func save() {
		do {
			try viewContext.save()
		}
		catch {
			// Replace this implementation with code to handle the error appropriately.
			// fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
			let nsError = error as NSError
			fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
		}
	}
	
	public func setGoal(weight: Double) {
		guard let configuration = load() else {
			return
		}
		configuration.goalWeight = NSDecimalNumber(value: weight)
		goalWeight.value = configuration.goalWeight ?? 0
		save()
	}
}
						

