//
//  SessionViewModel.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import Combine

class SessionViewModel: ObservableObject {
    @Published var sessions: [ClimbingSession] = []
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        // 저장된 모든 세션 로드
        sessions = SessionManager.shared.getAllSessions()
        
        // 최신 녹화 기준으로 정렬
        sessions.sort { $0.date > $1.date }
    }
    
    func deleteSession(at indexSet: IndexSet) {
        for index in indexSet {
            SessionManager.shared.deleteSession(withId: sessions[index].id)
        }
        loadSessions()
    }
}
