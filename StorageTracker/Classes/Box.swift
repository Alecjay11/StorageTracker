//
//  Box.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/14/25.
//

import Foundation

struct Box: Identifiable, Codable {
    var id: String = UUID().uuidString
    var items: [String]
    var name: String
    var photoURLs: [String] = []
    var location: String
    var locationNotes: String

    init(id: String = UUID().uuidString, items: [String] = [], name: String = "", photoURLs: [String] = [],location: String = "",
         locationNotes: String = "") {
        self.id = id
        self.items = items
        self.name = name
        self.photoURLs = photoURLs
        self.location = location
            self.locationNotes = locationNotes
    }

    enum CodingKeys: String, CodingKey {
        case id
        case items
        case name
        case photoURLs
        case location
        case locationNotes
    }
}


