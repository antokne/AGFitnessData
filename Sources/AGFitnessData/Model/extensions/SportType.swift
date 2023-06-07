//
//  File.swift
//  
//
//  Created by Antony Gardiner on 7/06/23.
//

import AntMessageProtocol
import SwiftStrava

extension SportType {
	var subSport: SubSport {
		switch self {
		case .alpineSki:
			return .resort
		case .backcountrySki:
			return .backcountry
		case .canoeing:
			return .invalid
		case .crossfit:
			return .invalid
		case .ebikeride:
			return .eBikeFitness
		case .elliptical:
			return .elliptical
		case .emountainbikeride:
			return .eBikeMountain
		case .golf:
			return .invalid
		case .gravelRide:
			return .gravelCycling
		case .handcycle:
			return .handCycling
		case .hike:
			return .trail
		case .iceSkate:
			return .invalid
		case .inlineSkate:
			return .invalid
		case .kayaking:
			return .invalid
		case .kitesurf:
			return .invalid
		case .mountainBikeRide:
			return .mountain
		case .nordicSki:
			return .skateSkiing
		case .ride:
			return .road
		case .rockClimbing:
			return .invalid
		case .rollerSki:
			return .invalid
		case .rowing:
			return .indoorRowing
		case .run:
			return .street
		case .sail:
			return .invalid
		case .skateboard:
			return .invalid
		case .snowboard:
			return .invalid
		case .snowshoe:
			return .invalid
		case .soccer:
			return .invalid
		case .stairStepper:
			return .invalid
		case .standUpPaddling:
			return .invalid
		case .surfing:
			return .invalid
		case .swim:
			return .lapSwimming
		case .trailRun:
			return .trail
		case .velomobile:
			return .invalid
		case .virtualRide:
			return .virtualActivity
		case .virtualRun:
			return .virtualActivity
		case .walk:
			return .casualWalking
		case .weightTraining:
			return .invalid
		case .wheelchair:
			return .invalid
		case .windsurf:
			return .invalid
		case .workout:
			return .invalid
		case .yoga:
			return .yoga
		}
	}
}
