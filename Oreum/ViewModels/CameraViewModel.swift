//
//  CameraViewModel.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI
import AVFoundation
import Combine

class CameraViewModel: ObservableObject {
    // 카메라 상태 변수
    @Published var isAuthorized = false
    @Published var isRecording = false
    @Published var showPoseOverlay = true
    @Published var recordingTime: TimeInterval = 0
    
    // 알림 관련 변수
    @Published var showAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    
    // 카메라 서비스 인스턴스
    private let cameraService = CameraService()
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
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
    }
    
    func toggleRecording() {
        if isRecording {
            cameraService.stopRecording()
        } else {
            cameraService.startRecording()
        }
    }
    
    func stopCamera() {
        cameraService.stopSession()
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
