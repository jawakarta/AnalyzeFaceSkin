//
//  Item.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 08/07/26.
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
