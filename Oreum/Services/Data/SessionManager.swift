//
//  SessionManager.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import UIKit
import AVFoundation

class SessionManager {
    static let shared = SessionManager()
    
    private let userDefaults = UserDefaults.standard
    private let sessionsKey = "climbing_sessions"
    
    private init() {}
    
    // 모든 세션 가져오기
    func getAllSessions() -> [ClimbingSession] {
        guard let data = userDefaults.data(forKey: sessionsKey) else {
            return []
        }
        
        do {
            let sessions = try JSONDecoder().decode([ClimbingSession].self, from: data)
            return sessions
        } catch {
            print("세션 데이터 디코딩 실패: \(error)")
            return []
        }
    }
    
    // 세션 저장하기
    func saveSession(_ session: ClimbingSession) {
        var sessions = getAllSessions()
        
        // 디버깅 로그
        print("저장 전 세션 수: \(sessions.count)")
        print("저장할 세션 정보: ID=\(session.id), 제목=\(session.title), 비디오 URL=\(session.videoURL)")
           
        sessions.append(session)
        saveSessions(sessions)
        
        print("저장 후 세션 수: \(sessions.count)")
        
        // 썸네일 생성
        generateThumbnail(for: session)
    }
    
    // 세션 삭제하기
    func deleteSession(withId id: String) {
        var sessions = getAllSessions()
        
        // 삭제할 세션 찾기
        if let index = sessions.firstIndex(where: { $0.id == id }) {
            let session = sessions[index]
            
            // 세션 비디오 파일 삭제
            do {
                try FileManager.default.removeItem(at: session.videoURL)
                print("비디오 파일 삭제 성공: \(session.videoURL.lastPathComponent)")
            } catch {
                print("비디오 파일 삭제 실패: \(error)")
            }
            
            // 세션 썸네일 이미지 삭제
            if let thumbnailName = session.thumbnailImageName {
                let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let thumbnailURL = documentsPath.appendingPathComponent(thumbnailName)
                
                do {
                    try FileManager.default.removeItem(at: thumbnailURL)
                    print("썸네일 파일 삭제 성공: \(thumbnailName)")
                } catch {
                    print("썸네일 파일 삭제 실패: \(error)")
                }
            }
            
            // 세션 배열에서 삭제
            sessions.remove(at: index)
            saveSessions(sessions)
        }
    }
    
    // 세션 목록 저장하기
    private func saveSessions(_ sessions: [ClimbingSession]) {
        do {
            let data = try JSONEncoder().encode(sessions)
            userDefaults.set(data, forKey: sessionsKey)
        } catch {
            print("세션 데이터 인코딩 실패: \(error)")
        }
    }
    
    // 비디오 파일에서 썸네일 생성하기
    private func generateThumbnail(for session: ClimbingSession) {
        let asset = AVAsset(url: session.videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // 비디오의 1초 지점에서 썸네일 생성
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            
            // 썸네일 저장
            let thumbnailName = "thumbnail_\(session.id).jpg"
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let thumbnailURL = documentsPath.appendingPathComponent(thumbnailName)
            
            if let data = thumbnail.jpegData(compressionQuality: 0.7) {
                do {
                    try data.write(to: thumbnailURL)
                    
                    // 세션 업데이트
                    var updatedSession = session
                    updatedSession.thumbnailImageName = thumbnailName
                    
                    // 세션 목록 업데이트
                    var sessions = getAllSessions()
                    if let index = sessions.firstIndex(where: { $0.id == session.id }) {
                        sessions[index] = updatedSession
                        saveSessions(sessions)
                    }
                    
                    print("썸네일 저장 성공: \(thumbnailName)")
                } catch {
                    print("썸네일 저장 실패: \(error)")
                }
            }
        } catch {
            print("썸네일 생성 실패: \(error)")
        }
    }
    
    // 썸네일 이미지 가져오기
    func getThumbnailImage(for session: ClimbingSession) -> UIImage? {
        guard let thumbnailName = session.thumbnailImageName else {
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let thumbnailURL = documentsPath.appendingPathComponent(thumbnailName)
        
        do {
            let data = try Data(contentsOf: thumbnailURL)
            return UIImage(data: data)
        } catch {
            print("썸네일 이미지 로드 실패: \(error)")
            return nil
        }
    }
}
