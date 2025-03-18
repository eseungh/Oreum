//
//  ClimbingSession.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation

struct ClimbingSession: Identifiable, Codable {
    var id: String
    var title: String
    var date: Date
    var duration: TimeInterval
    var videoURL: URL
    var thumbnailImageName: String?
    
    init(id: String = UUID().uuidString, title: String, date: Date = Date(), duration: TimeInterval, videoURL: URL) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.videoURL = videoURL
    }
}
