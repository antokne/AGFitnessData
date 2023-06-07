//
//  BikeRelationshipProtocol.swift
//  Gruppo
//
//  Created by Antony Gardiner on 27/04/23.
//

import Foundation
import CoreData

// use when an entity has a relationship to a bike
public protocol BikeRelationshipProtocol {
	var bike: Bike? { get set }
}
