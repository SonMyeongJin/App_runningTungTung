//
//  Item.swift
//  RunningTungTung
//
//  Created by 손명진 on 9/5/25.
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
