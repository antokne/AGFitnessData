//
//  File.swift
//  
//
//  Created by Antony Gardiner on 16/06/23.
//

import Foundation
import CoreTransferable

extension Activity: Transferable {
	
	var url: URL? {
		guard let fileName else {
			return nil
		}
		return ActivityStorage.activityURL(from: fileName)
	}
	
	static public var transferRepresentation: some TransferRepresentation {
		FileRepresentation(exportedContentType: .fit) { fitFile in
			SentTransferredFile(fitFile.url!)
		}
	}
	
}
