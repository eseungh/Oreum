//
//  SessionDetailView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI
import AVKit

struct SessionDetailView: View {
    let session: ClimbingSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 비디오 플레이어
                VideoPlayerView(url: session.videoURL)
                    .frame(height: 240)
                    .cornerRadius(12)
                    .shadow(radius: 4)
                
                // 세션 정보
                VStack(alignment: .leading, spacing: 12) {
                    Text(session.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    HStack {
                        Label(formattedDate(session.date), systemImage: "calendar")
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label(formattedDuration(session.duration), systemImage: "clock")
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // 이 부분은 나중에 분석 기능 구현 시 채워질 예정입니다
                    Text("분석 결과")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text("이 세션에 대한 포즈 분석 결과는 아직 준비 중입니다.")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5)
            }
            .padding()
        }
        .navigationTitle("세션 상세")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }
    
    // 날짜 포맷팅 함수
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
        return formatter.string(from: date)
    }
    
    // 시간 포맷팅 함수
    private func formattedDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d분 %02d초", minutes, seconds)
    }
}
