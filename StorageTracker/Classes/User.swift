//
//  User.swift
//  StorageTracker
//
//  Created by Alec Newman on 3/14/25.
//


import Foundation

struct User: Identifiable, Codable {
    var UserID: String
    var email: String
    var firstName: String
    var lastName: String
    var boxes: [Box] = []
    var id: String {return UserID}
    var availableLocations: [String] = []

    init(UserID: String = "", firstName: String = "", lastName: String = "", email: String = "", boxes: [Box] = [], availableLocations: [String] = []) {
        self.UserID = UserID
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.boxes = boxes
        self.availableLocations = availableLocations
    }
    enum CodingKeys: String, CodingKey {
            case UserID = "userID"
            case email
            case firstName
            case lastName
            case boxes
        }
}

