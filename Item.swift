//
//  Item.swift
//  parasol
//
//  Created by Jia Xi Chen on 2024-08-27.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
