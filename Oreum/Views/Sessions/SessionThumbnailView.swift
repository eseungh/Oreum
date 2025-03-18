//
//  SessionThumbnailView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct SessionThumbnailView: View {
    let session: ClimbingSession
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 썸네일 이미지
            if let uiImage = SessionManager.shared.getThumbnailImage(for: session) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 180)
                    .cornerRadius(12)
                    .clipped()
            } else {
                // 썸네일이 없는 경우 대체 이미지
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay(
                        Image(systemName: "video.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
            }
            
            // 세션 정보 오버레이
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    // 녹화 시간 형식 변환
                    let minutes = Int(session.duration) / 60
                    let seconds = Int(session.duration) % 60
                    Text(String(format: "%d:%02d", minutes, seconds))
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Spacer()
                    
                    // 날짜 표시
                    Text(formattedDate(session.date))
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(12)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black.opacity(0)]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            )
            .cornerRadius(12)
        }
        .shadow(radius: 3)
    }
    
    // 날짜 포맷팅 함수
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
}
