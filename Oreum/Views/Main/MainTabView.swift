//
//  MainTabView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//
//  탭 기반 메인 뷰

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            CameraView()
                .tabItem {
                    Label("카메라", systemImage: "camera.fill")
                }
            
            AnalysisView()
                .tabItem {
                    Label("분석", systemImage: "chart.bar.fill")
                }
            
            SessionListView()
                .tabItem {
                    Label("세션", systemImage: "list.bullet")
                }
            
            SettingsView()
                .tabItem {
                    Label("설정", systemImage: "gear")
                }
        }
    }
}


#Preview {
    MainTabView()
        .modelContainer(for: Item.self, inMemory: true)
}
