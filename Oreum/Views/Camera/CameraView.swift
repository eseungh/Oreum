//
//  CameraView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isAuthorized {
                // 카메라 미리보기
                CameraPreviewView(session: viewModel.captureSession)
                    .edgesIgnoringSafeArea(.top)
                
                // 포즈 오버레이 (showPoseOverlay가 true일 때만 표시)
                if viewModel.showPoseOverlay, let pose = viewModel.detectedPose {
                    GeometryReader { geometry in
                        PoseOverlayView(
                            pose: pose,
                            frame: geometry.frame(in: .local)
                        )
                    }
                    .edgesIgnoringSafeArea(.top)
                }
                
                // 동작 유형 표시 (showPoseOverlay가 true일 때만 표시)
                if viewModel.showPoseOverlay, let movement = viewModel.detectedMovement {
                    VStack {
                        Spacer().frame(height: 100)
                        
                        HStack {
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(movement.movementType.rawValue)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text("신뢰도: \(Int(movement.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)
                            .padding(.trailing, 16)
                        }
                    }
                }
                
                // UI 오버레이
                VStack {
                    // 상단 영역 (녹화 타이머)
                    if viewModel.isRecording {
                        HStack {
                            RecordingTimerView(recordingTime: viewModel.recordingTime)
                            Spacer()
                        }
                        .padding(.top, 60)
                        .padding(.leading, 20)
                    } else {
                        HStack {
                            Spacer()
                        }
                        .padding(.top, 60)
                    }
                    
                    Spacer()
                    
                    // 하단 컨트롤
                    CameraControlsView(
                        isRecording: $viewModel.isRecording,
                        showPoseOverlay: $viewModel.showPoseOverlay,
                        onRecordTapped: viewModel.toggleRecording
                    )
                }
            } else {
                // 카메라 권한이 없는 경우 (변경 없음)
                VStack(spacing: 20) {
                    Image(systemName: "camera.metering.unknown")
                        .font(.system(size: 80))
                        .foregroundColor(.gray)
                    
                    Text("카메라에 접근할 수 없습니다")
                        .font(.title)
                    
                    Text("이 앱은 클라이밍 포즈 분석을 위해 카메라 접근 권한이 필요합니다. 설정 앱에서 권한을 허용해주세요.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.gray)
                        .padding()
                    
                    Button("설정으로 이동") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
        .onDisappear {
            viewModel.stopCamera()
        }
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text(viewModel.alertTitle),
                message: Text(viewModel.alertMessage),
                dismissButton: .default(Text("확인"))
            )
        }
    }
}
