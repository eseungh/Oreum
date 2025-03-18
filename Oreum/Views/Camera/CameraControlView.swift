//
//  CameraControlView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct CameraControlsView: View {
    @Binding var isRecording: Bool
    @Binding var showPoseOverlay: Bool
    var onRecordTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 30) {
            // 포즈 오버레이 토글 버튼
            Button(action: {
                showPoseOverlay.toggle()
            }) {
                Image(systemName: showPoseOverlay ? "eye.fill" : "eye.slash.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            // 녹화 버튼
            Button(action: onRecordTapped) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                    
                    if isRecording {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.red)
                            .frame(width: 30, height: 30)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 70, height: 70)
                    }
                }
            }
            
            // 설정 버튼
            Button(action: {
                // 설정 액션
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
        }
        .padding(.bottom, 30)
    }
}
