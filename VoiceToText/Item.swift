//
//  Item.swift
//  VoiceToText
//
//  Created by Artem Mir on 21.03.26.
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
