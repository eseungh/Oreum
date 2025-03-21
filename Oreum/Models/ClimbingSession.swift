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
    private var videoFileName: String  // URL 대신 파일 이름만 저장
    var thumbnailImageName: String?
    var videoFileStatus: VideoFileStatus = .available
    enum VideoFileStatus: String, Codable {
        case available = "available"  // 파일 사용 가능
        case missing = "missing"      // 파일 누락됨
    }
    
    
    // 추가 속성들...
    
    // 계산 속성으로 실제 URL 반환
    var videoURL: URL {
           get {
               let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
               return documentsPath.appendingPathComponent(videoFileName)
           }
       }
    
    init(id: String = UUID().uuidString, title: String, date: Date = Date(), duration: TimeInterval, videoURL: URL) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.videoFileName = videoURL.lastPathComponent
    }
    
    // 파일 이름을 직접 저장하는 이니셜라이저 추가
    init(id: String = UUID().uuidString, title: String, date: Date = Date(), duration: TimeInterval, videoFileName: String) {
        self.id = id
        self.title = title
        self.date = date
        self.duration = duration
        self.videoFileName = videoFileName
    }
    
    // 비디오 파일이 누락되었음을 표시하는 메소드
       mutating func markVideoAsMissing() {
           self.videoFileStatus = .missing
       }
       
       // 비디오 파일 상태 확인 메소드
       func isVideoAvailable() -> Bool {
           return videoFileStatus == .available &&
                  FileManager.default.fileExists(atPath: videoURL.path)
       }
}
