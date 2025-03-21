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
    @State private var videoExists: Bool = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 비디오 존재 여부에 따라 다른 뷰 표시
                               if videoExists {
                                   // 기존 비디오 플레이어
                                   VideoPlayerView(url: session.videoURL)
                                       .frame(height: 640)
                                       .cornerRadius(12)
                                       .shadow(radius: 4)
                               } else {
                                   // 비디오 파일이 없는 경우 대체 뷰
                                   VStack {
                                       Image(systemName: "exclamationmark.triangle")
                                           .font(.system(size: 40))
                                           .foregroundColor(.orange)
                                           .padding()
                                       
                                       Text("비디오 파일을 찾을 수 없습니다")
                                           .font(.headline)
                                       
                                       Text("파일이 이동되었거나 삭제되었을 수 있습니다")
                                           .font(.subheadline)
                                           .foregroundColor(.secondary)
                                           .multilineTextAlignment(.center)
                                           .padding()
                                   }
                                   .frame(height: 640)
                                   .frame(maxWidth: .infinity)
                                   .background(Color.gray.opacity(0.1))
                                   .cornerRadius(12)
                               }
                
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
        .onAppear {
            // 뷰가 나타날 때 비디오 파일 존재 여부 확인
            checkVideoFile()
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
    
    private func checkVideoFile() {
          let fileExists = FileManager.default.fileExists(atPath: session.videoURL.path)
          print("세션 ID: \(session.id), 비디오 경로: \(session.videoURL.path), 파일 존재?: \(fileExists)")
          
          // 상태 업데이트
          videoExists = fileExists
      }
}
