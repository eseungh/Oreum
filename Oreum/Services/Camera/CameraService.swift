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
        guard !isRecording else {
            print("이미 녹화 중입니다.")
            return
        }
        print("녹화 시작 요청")
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        let fileURL = documentsPath.appendingPathComponent("climbing_\(dateString).mov")
        
        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
           print("startRecording 메소드 종료")
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
        print("didStartRecording 콜백 호출됨: \(fileURL.path)")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isRecording = true
            print("isRecording 상태 변경됨: \(self.isRecording)")
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("didFinishRecordingTo 콜백 호출됨: \(outputFileURL.path)")
        
        // 상태 업데이트는 모든 처리 전에 먼저 수행
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // 기존 상태 저장
            let wasRecording = self.isRecording
            // 상태 업데이트
            self.isRecording = false
            print("isRecording 상태 변경됨: \(wasRecording) -> \(self.isRecording)")
        }
        if let error = error {
            print("녹화 오류: \(error.localizedDescription)")
            // 심각한 오류인 경우 여기서 처리 중단
            if (error as NSError).domain == AVFoundationErrorDomain &&
                (error as NSError).code == AVError.diskFull.rawValue {
                return
            }
            
            
            // 녹화 지속 시간 계산
            let duration = output.recordedDuration.seconds
            
            // 날짜 포맷
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
            let formattedDate = dateFormatter.string(from: Date())
            let sessionTitle = "클라이밍 세션 - \(formattedDate)"
            
            // 임시 URL을 앱 문서 디렉토리로 이동
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = "climbing_\(UUID().uuidString).mov"
            let permanentURL = documentsPath.appendingPathComponent(fileName)
            
            do {
                // 기존 파일이 있다면 삭제
                if FileManager.default.fileExists(atPath: permanentURL.path) {
                    try FileManager.default.removeItem(at: permanentURL)
                }
                
                // 파일 이동 (복사 후 원본 삭제)
                try FileManager.default.copyItem(at: outputFileURL, to: permanentURL)
                try FileManager.default.removeItem(at: outputFileURL)
                
                SessionManager.shared.secureVideoFile(at: permanentURL)
                
                print("비디오 파일 성공적으로 저장됨: \(permanentURL.path)")
                
                // 세션 생성 (파일 이름만 저장)
                let session = ClimbingSession(
                    title: sessionTitle,
                    duration: duration,
                    videoFileName: fileName
                )
                
                // 세션 저장
                SessionManager.shared.saveSession(session)
                
                // 갤러리 저장 (선택 사항)
                UISaveVideoAtPathToSavedPhotosAlbum(
                    permanentURL.path,
                    nil,
                    nil,
                    nil
                )
            } catch {
                print("비디오 파일 저장 오류: \(error)")
            }
        }
    }
}
