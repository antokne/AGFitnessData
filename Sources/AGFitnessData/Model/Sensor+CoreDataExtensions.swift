//
//  Sensor+CoreDataExtensions.swift
//  Gruppo
//
//  Created by Antony Gardiner on 20/04/23.
//

import Foundation
import CoreData

public extension Sensor {
	
	class func sortedFetchRequest() -> NSFetchRequest<Sensor> {
		let fetchRequest = NSFetchRequest<Sensor>(entityName: "Sensor")
		let sortDescriptor = NSSortDescriptor(keyPath: \Sensor.name, ascending: true)
		fetchRequest.sortDescriptors = [sortDescriptor]
		return fetchRequest
	}
	
	class func findSensor(for serialNo: Int64) -> Sensor? {
		let fetchRequest = NSFetchRequest<Sensor>(entityName: "Sensor")
		fetchRequest.predicate = NSPredicate(format: "serialNo = %lld", serialNo)
		do {
			let results = try fetchRequest.execute()
			return results.first
		}
		catch {
			print(error)
			return nil
		}
	}

	@discardableResult
	class func add(controller: PersistenceController = PersistenceController.shared) -> Sensor {
		let newSensor = Sensor(context: controller.container.viewContext)
		newSensor.createdAt = Date()
		newSensor.updatedAt = newSensor.createdAt
		return newSensor
	}
	
	private func setChanged() {
		self.updatedAt = Date()
	}
	
	@discardableResult
	func setSerialNo(serialNo: Int64?) -> Sensor {
		if let serialNo {
			self.serialNo = serialNo
			setChanged()
		}
		return self
	}

	@discardableResult
	func setName(name: String?) -> Sensor {
		if let name {
			self.name = name
			setChanged()
		}
		return self
	}

	@discardableResult
	func setManufacturer(manufacturer: String?) -> Sensor {
		if let manufacturer {
			self.manufacturer = manufacturer
			setChanged()
		}
		return self
	}
	
	@discardableResult
	func setType(type: Int16?) -> Sensor {
		if let type {
			self.type = type
			setChanged()
		}
		return self
	}
	
	@discardableResult
	func setBattery(battery: Int16?) -> Sensor {
		if let battery {
			self.battery = battery
			setChanged()
		}
		return self
	}
	
	func save(controller: PersistenceController = PersistenceController.shared) {
		controller.save()
	}
	
	func delete(controller: PersistenceController = PersistenceController.shared) {
		controller.delete(object: self)
	}
}

extension Sensor: BikeRelationshipProtocol { }


