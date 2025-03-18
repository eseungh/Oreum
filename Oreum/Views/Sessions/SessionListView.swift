//
//  SessionListView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct SessionListView: View {
    @StateObject private var viewModel = SessionViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.sessions.isEmpty {
                    // 세션이 없는 경우
                    VStack(spacing: 20) {
                        Image(systemName: "video.slash.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("저장된 세션이 없습니다")
                            .font(.title2)
                        
                        Text("카메라 탭에서 클라이밍 세션을 녹화해보세요!")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                    }
                } else {
                    // 세션 목록 표시
                    List {
                        ForEach(viewModel.sessions) { session in
                            NavigationLink(destination: SessionDetailView(session: session)) {
                                VStack {
                                    SessionThumbnailView(session: session)
                                        .frame(height: 180)
                                    
                                    Spacer()
                                        .frame(height: 8)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: viewModel.deleteSession)
                    }
                    .listStyle(InsetGroupedListStyle())
                }
            }
            .navigationTitle("내 세션")
            .toolbar {
                if !viewModel.sessions.isEmpty {
                    EditButton()
                }
            }
            .onAppear {
                viewModel.loadSessions()
            }
        }
    }
}
