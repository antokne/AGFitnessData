//
//  ActivityStorage.swift
//  RaceWeight
//
//  Created by Antony Gardiner on 7/12/22.
//

import Foundation
import CoreData
import FitDataProtocol
import AntMessageProtocol
import Logging
import SwiftStrava
import AGCore
import AGFitCore

enum ActivityError: Error {
	case fitFileNotFound
	case invalidSessionCount /// Incorrect number of session messages in fit file (can be only one at the moment)
	case failedToCreateActivity
	case activityExists
}

public class ActivityStorage {
	
	private var logger = Logger(label: "ActivityStorage")
	
	var viewContext = PersistenceController.shared.container.viewContext
	
	// SINGELTON INSTANCE
	public static let shared: ActivityStorage = ActivityStorage()
	
	private static var defaultSubFolder: AGUserDefaultStringValue = AGUserDefaultStringValue(keyName: "activity-folder", defaultValue: "activities")
	
	
	public init() {
		logger.logLevel = .debug
	}
	
	public init(context: NSManagedObjectContext) {
		self.viewContext = context
	}
	
	public func add(activity: Activity) -> Bool {
		
		do {
			try activity.managedObjectContext?.save()
		}
		catch {
			logger.debug("Failed to add activity \(activity).")
			return false
		}
		return true
	}
	
	public func delete(activity: Activity) {
		
		do {
			let filename = activity.fileName
			
			activity.delete(context: viewContext)
			try viewContext.save()
			
			guard let filename else {
				logger.debug("activity has no filename set cannot delete fit file.")
				return
			}
			
			guard let activityFileURL = ActivityStorage.activitiesDirectoryURL?.appending(component: filename) else {
				logger.debug("activity generated url is nil. bad path for \(filename)")
				return
			}
			
			try FileManager.default.removeItem(at: activityFileURL)
		}
		catch {
			logger.debug("Failed to delete activity \(activity) \(error).")
		}
	}
	
	/// Imports a fit activity from fit file
	/// - Parameter url: the location of the fit file to import
	public func importActivity(from url: URL) async throws {
		
		guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) == true else {
			logger.debug("fit file \(url) does not exist stopping.")
			throw ActivityError.fitFileNotFound
		}
		
		guard let activityFileURL = ActivityStorage.activityURL(from: url) else {
			throw ActivityError.fitFileNotFound
		}
		
		if ActivityStorage.activityExists(from: url) {
			logger.debug("fit file \(url) already imported stopping.")
			throw ActivityError.activityExists
		}
		
		var success = true
		var newActivity: Activity? = nil
		let fitFilename = url.lastPathComponent
		
		defer {
			if !success {
				logger.error("error adding file \(url) removing file and model record.")
				logger.error("Removing file \(activityFileURL).")

				if FileManager.default.fileExists(atPath: activityFileURL.path(percentEncoded: false)) {
					try? FileManager.default.removeItem(at: activityFileURL)
				}
				
				if let activity = newActivity {
					viewContext.delete(activity)
				}
			}
			
			// save the changes
			PersistenceController.shared.save()
		}
		
		// parse fit file
		let fitReader = AGFitReader(fileUrl: url)
		fitReader.read()
		let messages = fitReader.messages
		
		// create model record
		newActivity = Activity(context: viewContext)
		
		guard let newActivity else {
			success = false
			throw ActivityError.failedToCreateActivity
		}

		// update activity record
		let fitSessions = messages.filter { ($0 as? SessionMessage) != nil }
		guard fitSessions.count == 1 else {
			success = false
			throw ActivityError.invalidSessionCount
		}
		
		if let sessionMessage = fitSessions.first as? SessionMessage {
			newActivity.set(from: sessionMessage)
		}
		else {
			success = false
		}
		
		// copy fit file & set filename
		do {
			try FileManager.default.copyItem(at: url, to: activityFileURL)
			newActivity.fileName = fitFilename
		}
		catch {
			success = false
			logger.debug("Failed to copy file \(error).")
		}

		await analyseActivity(activity: newActivity)
	}
	
	// MARK: - Update activities looking at fit file data.
	
	/// Go through all activities an do some things...
	public func analyseAllActivities() async {
		
		guard let activities = try? viewContext.fetch(Activity.fetchRequest()) else {
			logger.debug("analyseAllActivities - no activities found exiting.")
			return
		}
		
		let activitiesWithFitFiles = activities.filter( { $0.fileName != nil })
		
		for activity in activitiesWithFitFiles {
			await analyseActivity(activity: activity)
		}
	}
	
	/// Check activity and then look for new sensors
	/// - Parameter activity: activity to check
	public func analyseActivity(activity: Activity) async {
		
		// Currently just check for sensors
		// load fit and pass to sensor checker.
		guard let filename = activity.fileName else {
			logger.debug("analyseActivity - no path skipping.")
			return
		}
		
		guard let activityURL = ActivityStorage.activityURL(from: filename) else {
			logger.debug("analyseActivity - no url skipping.")
			return
		}
		
		// parse fit file
		let fitReader = AGFitReader(fileUrl: activityURL)
		fitReader.read()
		let messages = fitReader.messages
		
		let allDeviceInfoMessages = filterDeviceInfoMessages(messages: messages)
		let lastUniqueDeviceInfoMessages = filterLastDeviceInfoMessagesWithSerialNo(deviceInfoMessages: allDeviceInfoMessages)
				
		await checkForNewSensors(deviceInfoMessages: lastUniqueDeviceInfoMessages)
		
		await assignBikeToActivity(activity: activity, deviceInfoMessages: lastUniqueDeviceInfoMessages)
	}
	
	/// Go through all DeviceInfoMessages and see if we have some new sensors
	/// - Parameter messages: the current fit messages
	/// - Parameter deviceInfoMessages: messages to look for new sensors
	/// - Parameter sensorStorage: inject if needed for testing.
	public func checkForNewSensors(deviceInfoMessages: [DeviceInfoMessage], sensorStorage: SensorStorage = SensorStorage()) async {
		
		// Pass device info messages to the sensor parser.
		await sensorStorage.processDeviceInfoMessages(deviceInfoMessages: deviceInfoMessages)
	}
	
	/// Attempt to assign a bike to an activity looking at the sensors and matching to device info messsages with the
	/// same serial number, then update all components on that bike
	/// - Parameters:
	///   - activity: the activity to assign
	///   - deviceInfoMessages: to match to sensors
	///   - sensorStorage: inject if needed for testing.
	public func assignBikeToActivity(activity: Activity,
							  deviceInfoMessages: [DeviceInfoMessage],
							  sensorStorage: SensorStorage = SensorStorage()) async {
		
		for deviceInfoMessage in deviceInfoMessages {
			
			// ensure we have a serial no
			guard let serialNo = deviceInfoMessage.serialNumber else {
				continue
			}
			
			// find existing sensor for serial no
			guard let existingSensor = await sensorStorage.findSensor(serialNo: Int64(serialNo)) else {
				continue
			}
			
			// do we have a bike for this sensor?
			guard let bike = existingSensor.bike else {
				continue
			}
			
			// now update activity to use this bike.
			activity.bike = bike
			bike.updateBike(for: activity)
			
			// we can stop once we have found a sensor to use
			return
		}
	}
	
	/// Filters fit messages for just the DeviceInfoMessages
	/// - Parameter messages: all fit messages
	/// - Returns: array of DeviceInfoMessages
	public func filterDeviceInfoMessages(messages: [FitMessage]) -> [DeviceInfoMessage] {
		
		// Filter only device info messages (still as FitMessage base type here)
		let messagesFiltered = messages.filter { ($0 as? DeviceInfoMessage) != nil }
		
		// Convert to DeviceInfoMessages this will always succeed.
		let deviceInfoMessages = messagesFiltered.map( { $0 as! DeviceInfoMessage } )
		
		return deviceInfoMessages
	}
	
	/// Filters messsages for the last ones that have a serial no.
	/// Note: We want the last ones because they are the newest message for that sensor.
	/// - Parameter deviceInfoMessages: array of DeviceInfoMessages
	/// - Returns: unique array of messages with serial numbers.
	public func filterLastDeviceInfoMessagesWithSerialNo(deviceInfoMessages: [DeviceInfoMessage]) -> [DeviceInfoMessage] {
		
		// remove all that have no serialNo
		let deviceswithSerialNo = deviceInfoMessages.filter( { $0.serialNumber != nil } )
		
		// filter to get the last one of each device index
		var sensors: [UInt8: DeviceInfoMessage] = [: ]
		
		// If we iterate over all the device info messages and
		// set into the dictionary then only the last ones will exist
		// with that index.
		for deviceInfoMessage in deviceswithSerialNo {
			if let index = deviceInfoMessage.deviceIndex?.index {
				sensors[index] = deviceInfoMessage
			}
		}
		
		// Map dictionary into an array of DeviceInfoMessages
		return sensors.map( { $0.value } )
	}
	
	// MARK: - Import from Strava
	
	public func importStrava(activity: SummaryActivity, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) throws {

		logger.info("importStrava activity start")

		// create model record
		let newActivity = Activity(context: context)
		
		if let encodedPolyline = activity.map?.summaryPolyline {
			logger.debug("length of polyline = \(encodedPolyline.count)")
			
			newActivity.polyline = encodedPolyline
		}
		else {
			logger.warning("No polyline cannot generated an image.")
		}
		
		newActivity.set(from: activity)
		let success = add(activity: newActivity)
		if success == false {
			logger.error("Failed to add strava activity")
		}
		
		// If we can find the bike then update the relationship.
		if let gearId = activity.gearId,
		   let bike = Bike.findBike(by: gearId, context) {
				newActivity.bike = bike
			
			bike.updateBike(for: newActivity)
		}
		
		try? context.save()
	}
	
	public func importStrava(activity: DetailedActivity, context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) throws {
		
		logger.debug("importStrava activity start")
		
		// create model record
		let newActivity = Activity(context: context)
		
		if let encodedPolyline = activity.map?.summaryPolyline {
			logger.debug("length of polyline = \(encodedPolyline.count)")
			
			newActivity.polyline = encodedPolyline
		}
		else {
			logger.warning("No polyline cannot generated an image.")
		}
		
		newActivity.set(from: activity)
		let success = add(activity: newActivity)
		if success == false {
			logger.error("Failed to add strava activity")
		}
		
		// If we can find the bike then update the relationship.
		if let gearId = activity.gearId,
		   let bike = Bike.findBike(by: gearId, context) {
			newActivity.bike = bike
			
			bike.updateBike(for: newActivity)
		}
		
		try? context.save()
	}
	
}

extension ActivityStorage {
	
	static public func setDefault(folder: String) {
		defaultSubFolder.stringValue = folder
	}
	
	/// Directory location that all fit files are saved into
	static public var activitiesDirectoryURL: URL? {
		AGFileManager.documentsSubDirectory(path: defaultSubFolder.stringValue)
	}
	
	// MARK: - Import from a URL
	
	/// Attempts to generate the activity path url for the passed url
	/// - Parameter url: the url of activity to potentially import
	/// - Returns: activity generated url
	static public func activityURL(from url: URL) -> URL? {
		
		let fitFilename = url.lastPathComponent
		return activityURL(from: fitFilename)
	}
	
	static public func activityURL(from fitFilename: String) -> URL? {
		
		guard let activityFileURL = ActivityStorage.activitiesDirectoryURL?.appending(component: fitFilename) else {
			return nil
		}
		return activityFileURL
	}
	
	/// Checks to see if a file at url exists in activity folder with the same base name
	/// - Parameter url: url of activity to check
	/// - Returns: true if exists
	static public func activityExists(from url: URL) -> Bool {
		guard let activityFileURL = activityURL(from: url) else {
			return false
		}
		return FileManager.default.fileExists(atPath: activityFileURL.path(percentEncoded: false))
	}
}
