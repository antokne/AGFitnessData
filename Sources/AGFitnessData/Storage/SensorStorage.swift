//
//  SensorStorage.swift
//  Gruppo
//
//  Created by Antony Gardiner on 20/04/23.
//

import Foundation
import OSLog
import FitDataProtocol

public class SensorStorage {

	private var persistenceController: PersistenceController
	private var logger = Logger(subsystem: "com.antokne.fitnessdata", category: "SensorStorage")

	public init(persistenceController: PersistenceController = PersistenceController.shared) {
		self.persistenceController = persistenceController
	}
	
	/// For each unique device info message that has a serial no create or update a sensor object
	/// - Parameter deviceInfoMessages: unique list of sensors
	func processDeviceInfoMessages(deviceInfoMessages: [DeviceInfoMessage]) async {
		
		for deviceInfoMessage in deviceInfoMessages {
			
			guard let serialNo = deviceInfoMessage.serialNumber else {
				logger.warning("No serial number for sensor \(deviceInfoMessage.name)")
				continue
			}
			
			if let existingSensor = await findSensor(serialNo: Int64(serialNo)) {
				await updateSensor(existingSensor: existingSensor, using: deviceInfoMessage)
			}
			else {
				await addSensor(using: deviceInfoMessage)
			}
		}
	}

	func addSensor(using deviceInfoMessage: DeviceInfoMessage) async {
		
		guard let serialNo = deviceInfoMessage.serialNumber else {
			logger.warning("No serial number for sensor \(deviceInfoMessage.name)")
			return
		}
		
		await persistenceController.container.viewContext.perform { [weak self] in
			
			let newSensor = Sensor.add()
				.setName(name: deviceInfoMessage.productName)
				.setSerialNo(serialNo: Int64(serialNo))
			
			if let deviceType = deviceInfoMessage.deviceType {
				newSensor.setType(type: Int16(deviceType.rawValue))
			}
			
			if let battery = deviceInfoMessage.batteryStatus {
				newSensor.setBattery(battery: Int16(battery.rawValue))
			}
			
			if let manufacturer = deviceInfoMessage.manufacturer {
				newSensor.setManufacturer(manufacturer: manufacturer.name)
			}
			
			// save Changes
			self?.persistenceController.save()
		}
	}
	
	func updateSensor(existingSensor: Sensor, using deviceInfoMessage: DeviceInfoMessage) async {
			
		await persistenceController.container.viewContext.perform { [weak self] in
			
				if let battery = deviceInfoMessage.batteryStatus {
					existingSensor.setBattery(battery: Int16(battery.rawValue))
					existingSensor.updatedAt = Date()
				}
				
				if let manufacturer = deviceInfoMessage.manufacturer {
					existingSensor.setManufacturer(manufacturer: manufacturer.name)
				}
			
			// save Changes
			self?.persistenceController.save()
		}
	}
	
	func findSensor(serialNo: Int64) async -> Sensor? {
		await persistenceController.container.viewContext.perform {
			let existingSensor = Sensor.findSensor(for: Int64(serialNo))
			return existingSensor
		}
	}
}
