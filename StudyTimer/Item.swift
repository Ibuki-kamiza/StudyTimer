//
//  Item.swift
//  StudyTimer
//
//  Created by pc on 2025/11/03.
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
