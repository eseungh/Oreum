//
//  CameraView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var poseViewModel = PoseEstimationViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.isAuthorized {
                CameraPreviewView(session: viewModel.captureSession)
                    .edgesIgnoringSafeArea(.top)
                
                if viewModel.showPoseOverlay && !poseViewModel.currentJoints.isEmpty {
                    PoseOverlayView(
                        joints: poseViewModel.currentJoints,
                        viewSize: UIScreen.main.bounds.size
                    )
                    .edgesIgnoringSafeArea(.all)
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
        // ZStack 자체에는 edgesIgnoringSafeArea 사용하지 않음
        .onAppear {
            viewModel.checkPermissions()
            
            //포즈 추정 시작 추가
            if viewModel.isAuthorized && !poseViewModel.isProcessingLiveVideo {
                poseViewModel.startLiveDetection(with: viewModel.captureSession)
                }
            }
                
        .onDisappear {
            viewModel.stopCamera()
            
            //포즈 추정 중지 추가
            if poseViewModel.isProcessingLiveVideo {
                poseViewModel.stopLiveDetection()
            }
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
