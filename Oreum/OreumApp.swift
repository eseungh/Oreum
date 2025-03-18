//
//  OreumApp.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

@main
struct OreumApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .background(Color.white)
                .preferredColorScheme(.light)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .background {
                // 앱이 백그라운드로 갈 때 필요한 데이터 저장
                print("앱이 백그라운드로 진입, 데이터 저장 시도")
                // 여기서 필요한 데이터 저장 로직 실행
            }
        }
    }
}
