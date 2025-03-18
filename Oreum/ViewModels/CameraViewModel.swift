//
//  CameraViewModel.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI
import AVFoundation
import Combine
import Vision

class CameraViewModel: ObservableObject {
    // 카메라 상태 변수
    @Published var isAuthorized = false
    @Published var isRecording = false
    @Published var showPoseOverlay = true
    @Published var recordingTime: TimeInterval = 0
    
    // 포즈 추정 관련 변수
    @Published var detectedPose: PoseObservation?
    @Published var detectedMovement: MovementAnalysis?
    
    // 알림 관련 변수
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // 카메라 서비스 인스턴스
    private let cameraService = CameraService()
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // 포즈 추정 뷰모델
    private let poseEstimationViewModel = PoseEstimationViewModel()
    
    // 캡처 세션 접근자 추가
    var captureSession: AVCaptureSession {
        return cameraService.captureSession
    }
    
    init() {
        setupSubscriptions()
        checkPermissions()
    }
    
    private func setupSubscriptions() {
        // 카메라 서비스 상태 변화 구독
        cameraService.$isRecording
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isRecording in
                self?.isRecording = isRecording
                
                if isRecording {
                    self?.startTimer()
                } else {
                    self?.stopTimer()
                    self?.recordingTime = 0
                }
            }
            .store(in: &cancellables)
        
        // 포즈 추정 결과 구독
        poseEstimationViewModel.$currentPose
            .receive(on: DispatchQueue.main)
            .sink { [weak self] pose in
                if self?.showPoseOverlay == true {
                    self?.detectedPose = pose
                }
            }
            .store(in: &cancellables)
        
        poseEstimationViewModel.$currentMovement
            .receive(on: DispatchQueue.main)
            .sink { [weak self] movement in
                self?.detectedMovement = movement
            }
            .store(in: &cancellables)
        
        // showPoseOverlay 변화 감지
        $showPoseOverlay
            .sink { [weak self] showOverlay in
                if !showOverlay {
                    self?.detectedPose = nil
                }
            }
            .store(in: &cancellables)
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isAuthorized = true
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.showPermissionAlert()
                    }
                }
            }
        case .denied, .restricted:
            isAuthorized = false
            showPermissionAlert()
        @unknown default:
            isAuthorized = false
            showPermissionAlert()
        }
    }
    
    private func setupCamera() {
        cameraService.setupSession()
        cameraService.startSession()
        
        // 포즈 추정 설정
        if showPoseOverlay {
            setupPoseEstimation()
        }
    }
    
    func toggleRecording() {
        if isRecording {
            cameraService.stopRecording()
        } else {
            cameraService.startRecording()
        }
    }
    
    func stopCamera() {
        poseEstimationViewModel.stopVideoProcessing(for: captureSession)
        cameraService.stopSession()
    }
    
    private func setupPoseEstimation() {
        poseEstimationViewModel.setupVideoProcessing(for: captureSession)
    }
    
    // 포즈 오버레이 표시 전환
    func togglePoseOverlay() {
        showPoseOverlay.toggle()
        
        if showPoseOverlay {
            setupPoseEstimation()
        } else {
            poseEstimationViewModel.stopVideoProcessing(for: captureSession)
            detectedPose = nil
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingTime += 1
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func showPermissionAlert() {
        alertTitle = "카메라 권한 필요"
        alertMessage = "클라이밍 분석을 위해 카메라 접근 권한이 필요합니다. 설정에서 권한을 허용해주세요."
        showAlert = true
    }
}
