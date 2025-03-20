//
//  MainTabView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//
//  탭 기반 메인 뷰

import SwiftUI

struct MainTabView: View {
    init() {
        UITabBar.appearance().backgroundColor = .white
    }
    
    var body: some View {
        TabView {
            
            AnalysisView()
                .tabItem {
                    Label("오름", systemImage: "chart.bar.fill")
                }
            
            CameraView()
                .tabItem {
                    Label("카메라", systemImage: "camera.fill")
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
        .modelContainer(for: Item.self, inMemory: false)
}
