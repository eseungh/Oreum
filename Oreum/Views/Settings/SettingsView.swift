//
//  SettingsView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("일반")) {
                    Text("앱 버전: 1.0.0")
                    Text("기기: iPhone")
                }
                
                Section(header: Text("카메라")) {
                    Text("해상도 설정")
                    Text("포즈 오버레이 표시")
                }
                
                Section(header: Text("분석")) {
                    Text("분석 민감도")
                    Text("동작 인식 설정")
                }
                
                Section(header: Text("정보")) {
                    Text("개발자 정보")
                    Text("오픈소스 라이선스")
                }
            }
            .navigationTitle("설정")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
