//
//  PoseEstimationViewModel.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import Vision
import Combine
import AVFoundation

class PoseEstimationViewModel: NSObject, ObservableObject {
    // 현재 인식된 관절 포인트
    @Published var currentJoints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
    
    // 실시간 포즈 인식 활성화 여부
    @Published var isProcessingLiveVideo = false
    
    // 카메라 출력 - 실시간 프레임 캡처용
    private var videoOutput: AVCaptureVideoDataOutput?
    private var captureSession: AVCaptureSession?
    
    // 디스패치 큐
    private let processingQueue = DispatchQueue(label: "com.oreum.poseEstimation", qos: .userInitiated)
    
    // 실시간 포즈 인식 시작
    func startLiveDetection(with session: AVCaptureSession) {
        guard !isProcessingLiveVideo else { return }
        
        self.captureSession = session
        
        // 이미 연결된 videoOutput이 있는지 확인
        for output in session.outputs {
            if output is AVCaptureVideoDataOutput {
                session.removeOutput(output)
            }
        }
        
        // 비디오 출력 설정
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: processingQueue)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
            
            // 연결 방향 설정
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = false
                }
            }
            
            isProcessingLiveVideo = true
        }
    }
    
    // 실시간 포즈 인식 중지
    func stopLiveDetection() {
        guard isProcessingLiveVideo, let session = captureSession, let videoOutput = videoOutput else { return }
        
        session.removeOutput(videoOutput)
        self.videoOutput = nil
        isProcessingLiveVideo = false
        
        // 관절 포인트 초기화
        DispatchQueue.main.async {
            self.currentJoints = [:]
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PoseEstimationViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isProcessingLiveVideo, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // 포즈 추정 수행
        PoseEstimator.shared.detectPose(from: pixelBuffer) { observation in
            guard let observation = observation else { return }
            
            // 관절 위치 추출
            let joints = PoseEstimator.shared.getJointsPositions(from: observation)
            
            // UI 업데이트는 메인 스레드에서
            DispatchQueue.main.async {
                self.currentJoints = joints
            }
        }
    }
}
