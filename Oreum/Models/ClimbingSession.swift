//
//  ClimbingSession.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import Vision

struct PoseTimestampData: Codable {
    var timestamp: TimeInterval
    var joints: [String: CodablePoint]
    
    // CGPoint를 Codable로 만들기 위한 래퍼 구조체
    struct CodablePoint: Codable {
        var x: CGFloat
        var y: CGFloat
        
        func toCGPoint() -> CGPoint {
            return CGPoint(x: x, y: y)
        }
        
        static func from(_ point: CGPoint) -> CodablePoint {
            return CodablePoint(x: point.x, y: point.y)
        }
    }
    
    // VNHumanBodyPoseObservation.JointName 딕셔너리를 받는 초기화 메서드
    init(timestamp: TimeInterval, joints: [VNHumanBodyPoseObservation.JointName: CGPoint]) {
        self.timestamp = timestamp
        self.joints = [:]
        
        // 각 관절을 문자열 식별자로 변환
        for (key, value) in joints {
            // 관절 이름을 문자열로 직접 변환 (예: "nose", "neck" 등)
            let jointString = String(describing: key)
            self.joints[jointString] = CodablePoint.from(value)
        }
    }
    
    // 관절 데이터를 딕셔너리로 반환 (Vision 타입에 종속되지 않음)
    func getJointsAsDictionary() -> [String: CGPoint] {
        var result: [String: CGPoint] = [:]
        
        for (key, codablePoint) in joints {
            result[key] = codablePoint.toCGPoint()
        }
        
        return result
    }
}

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
    
