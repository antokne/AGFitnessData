//
//  File.swift
//  
//
//  Created by Antony Gardiner on 16/06/23.
//

import Foundation
import CoreTransferable

@available(iOS 17.0, macOS 14.0, *)
extension Activity: Transferable {
	
	var url: URL? {
		guard let fileName else {
			return nil
		}
		return ActivityStorage.activityURL(from: fileName)
	}
		
	public static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(exportedContentType: .data) {
			fitFile in
			if let url = fitFile.url {
				return (try? Data(contentsOf: url)) ?? Data()
			} else {
				return Data()
			}
		}
		.suggestedFileName {
			fitFile in
			return fitFile.fileName
		}
	}
}
