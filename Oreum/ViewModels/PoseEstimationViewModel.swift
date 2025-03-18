//
//  PoseEstimationViewModel.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import Combine
import AVFoundation
import AVKit
import UIKit
import Vision

class PoseEstimationViewModel: ObservableObject {
    // 출력 데이터
    @Published var currentPose: PoseObservation?
    @Published var currentMovement: MovementAnalysis?
    @Published var isProcessing: Bool = false
    
    // 포즈 추정기와 프로세서
    private let poseEstimator = PoseEstimator()
    private let poseProcessor = PoseProcessor()
    
    // 비디오 캡처를 위한 출력
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var videoDataOutputQueue = DispatchQueue(label: "VideoDataOutput", qos: .userInitiated)
    
    // 이벤트 구독 저장
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupEstimator()
        setupProcessor()
    }
    
    private func setupEstimator() {
        // 포즈 추정기 델리게이트 설정
        poseEstimator.delegate = self
    }
    
    private func setupProcessor() {
        // 동작 감지 콜백 설정
        poseProcessor.onMovementDetected = { [weak self] movementAnalysis in
            DispatchQueue.main.async {
                self?.currentMovement = movementAnalysis
            }
        }
    }
    
    // 비디오 처리 설정
    func setupVideoProcessing(for session: AVCaptureSession) {
        // 현재 세션에 이미 비디오 데이터 출력이 있으면 제거
        for output in session.outputs {
            if output is AVCaptureVideoDataOutput {
                session.removeOutput(output)
            }
        }
        
        session.beginConfiguration()
        
        // 비디오 데이터 출력 설정
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: videoDataOutputQueue)
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            
            // 인터페이스 방향에 맞게 비디오 방향 설정
            if let connection = videoOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoMirroringSupported {
                    connection.isVideoMirrored = true // 전면 카메라 사용 시
                }
            }
            
            self.videoDataOutput = videoOutput
        }
        
        session.commitConfiguration()
    }
    
    // 비디오 처리 중지
    func stopVideoProcessing(for session: AVCaptureSession) {
        if let videoOutput = self.videoDataOutput {
            session.beginConfiguration()
            session.removeOutput(videoOutput)
            session.commitConfiguration()
            self.videoDataOutput = nil
        }
        
        // 포즈 프로세서 상태 초기화
        poseProcessor.reset()
        
        // 현재 포즈 및 동작 데이터 초기화
        DispatchQueue.main.async { [weak self] in
            self?.currentPose = nil
            self?.currentMovement = nil
            self?.isProcessing = false
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension PoseEstimationViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard !isProcessing, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        isProcessing = true
        
        // 타임스탬프 추출
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer).seconds
        
        // 포즈 추정 처리
        poseEstimator.processImage(pixelBuffer, timestamp: timestamp)
    }
}

// MARK: - PoseEstimatorDelegate
extension PoseEstimationViewModel: PoseEstimatorDelegate {
    func poseEstimator(_ estimator: PoseEstimator, didDetectPose pose: PoseObservation) {
        // 포즈 데이터 업데이트
        DispatchQueue.main.async { [weak self] in
            self?.currentPose = pose
            self?.isProcessing = false
        }
        
        // 포즈 프로세서에 전달하여 동작 분석
        poseProcessor.processPose(pose)
    }
    
    func poseEstimator(_ estimator: PoseEstimator, didFailWithError error: Error) {
        print("포즈 추정 오류: \(error.localizedDescription)")
        DispatchQueue.main.async { [weak self] in
            self?.isProcessing = false
        }
    }
}
