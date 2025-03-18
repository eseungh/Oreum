//
//  CameraService.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import AVFoundation
import UIKit

class CameraService: NSObject, ObservableObject {
    @Published var isRecording = false
    
    let captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    // 디바이스 종류에 따라 적절한 해상도 설정
    private func getPreset() -> AVCaptureSession.Preset {
        return .high
    }
    
    // 카메라 세션 설정
    func setupSession() {
        captureSession.beginConfiguration()
        captureSession.sessionPreset = getPreset()
        
        // 비디오 입력 설정
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice) else {
            print("카메라 입력 설정 실패")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        }
        
        // 오디오 입력 설정
        guard let audioDevice = AVCaptureDevice.default(for: .audio),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            print("오디오 입력 설정 실패")
            captureSession.commitConfiguration()
            return
        }
        
        if captureSession.canAddInput(audioInput) {
            captureSession.addInput(audioInput)
        }
        
        // 비디오 출력 설정
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }
        
        captureSession.commitConfiguration()
    }
    
    // 카메라 세션 시작
    func startSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
    
    // 카메라 세션 중지
    func stopSession() {
        if captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    // 녹화 시작
    func startRecording() {
        guard !isRecording else { return }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let fileURL = documentsPath.appendingPathComponent("climbing_\(dateString).mov")
        
        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
    
    // 녹화 중지
    func stopRecording() {
        guard isRecording else { return }
        videoOutput.stopRecording()
    }
}

// AVCaptureFileOutputRecordingDelegate 프로토콜 구현

extension CameraService: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.isRecording = true
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        DispatchQueue.main.async {
            self.isRecording = false
        }
        
        if let error = error {
            print("녹화 오류: \(error.localizedDescription)")
            return
        }
        
        // 녹화 지속 시간 계산
        let duration = output.recordedDuration.seconds
        
        // 날짜 포맷
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
        let formattedDate = dateFormatter.string(from: Date())
        let sessionTitle = "클라이밍 세션 - \(formattedDate)"
        
        // 세션 생성 및 저장
        let session = ClimbingSession(
            title: sessionTitle,
            duration: duration,
            videoURL: outputFileURL
        )
        
        SessionManager.shared.saveSession(session)
        
        // 갤러리 저장 (선택 사항)
        UISaveVideoAtPathToSavedPhotosAlbum(
            outputFileURL.path,
            nil,
            nil,
            nil
        )
    }
}
