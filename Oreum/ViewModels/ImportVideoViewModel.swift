//
//  ImportVideoViewModel.swift
//  Oreum
//
//  Created by Seungho on 3/20/25.
//

import SwiftUI
import PhotosUI
import AVFoundation

struct ImportedVideoInfo: Identifiable {
    let id = UUID()
    let url: URL
    let date: Date
    let thumbnail: UIImage?
}

class ImportVideoViewModel: ObservableObject {
    @Published var showPhotoPicker = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var showSuccessAlert = false
    @Published var recentImports: [ImportedVideoInfo] = []
    
    func resetState() {
        error = nil
        isLoading = false
    }
    
    func handlePickedVideos(_ results: [PHPickerResult]) {
        guard let result = results.first else { return }
        
        isLoading = true
        error = nil
        
        // 비디오 로드 방식 변경
        result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.error = "비디오 로드 오류: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            
            guard let url = url else {
                DispatchQueue.main.async {
                    self.error = "비디오 URL을 가져올 수 없습니다."
                    self.isLoading = false
                }
                return
            }
            
            // 임시 파일을 앱 내부로 즉시 복사
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileName = url.lastPathComponent
            let destinationURL = documentsPath.appendingPathComponent("imported_\(UUID().uuidString)_\(fileName)")
            
            do {
                // 파일이 존재하는지 확인
                if FileManager.default.fileExists(atPath: url.path) {
                    // 파일을 즉시 복사
                    try FileManager.default.copyItem(at: url, to: destinationURL)
                    
                    // 메인 스레드에서 후속 처리
                    DispatchQueue.main.async {
                        self.processImportedVideo(at: destinationURL)
                    }
                } else {
                    DispatchQueue.main.async {
                        self.error = "파일이 존재하지 않습니다: \(url.path)"
                        self.isLoading = false
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = "파일 복사 오류: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    
    // 비디오 처리를 별도 메서드로 분리
    private func processImportedVideo(at url: URL) {
        // 비디오 속성 가져오기
        let asset = AVAsset(url: url)
        
        // 비디오 길이 구하기 (비동기 처리)
        asset.loadValuesAsynchronously(forKeys: ["duration"]) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                var durationError: NSError?
                let status = asset.statusOfValue(forKey: "duration", error: &durationError)
                
                guard status == .loaded else {
                    self.error = "비디오 길이를 확인할 수 없습니다: \(durationError?.localizedDescription ?? "알 수 없는 오류")"
                    self.isLoading = false
                    return
                }
                
                let duration = CMTimeGetSeconds(asset.duration)
                
                // 파일 복사 후 보안 속성 설정
                    SessionManager.shared.secureVideoFile(at: url)
                
                // 세션 생성
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy년 MM월 dd일 HH:mm"
                let formattedDate = dateFormatter.string(from: Date())
                let title = "가져온 세션 - \(formattedDate)"
                
                let session = ClimbingSession(
                    title: title,
                    duration: duration,
                    videoURL: url
                )
                
                // 세션 저장
                SessionManager.shared.saveSession(session)
                
                // 썸네일 생성 - 세션매니저의 저장 과정에서 자동 생성됨
                
                self.isLoading = false
                self.showSuccessAlert = true
            }
        }
    }
    
    private func copyVideoToDocuments(from tempURL: URL) {
        // 비디오 속성 가져오기
        let asset = AVAsset(url: tempURL)
        
        // 날짜 포맷 설정
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: Date())
        
        // 저장 경로 설정
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let destinationURL = documentsPath.appendingPathComponent("imported_\(dateString).mov")
        
        // 비디오 복사
        do {
            try FileManager.default.copyItem(at: tempURL, to: destinationURL)
            
            // 비디오 길이 구하기
            let duration = CMTimeGetSeconds(asset.duration)
            
            // 세션 생성
            let title = "가져온 세션 - \(dateString)"
            let session = ClimbingSession(
                title: title,
                duration: duration,
                videoURL: destinationURL
            )
            
            // 썸네일 생성
            let thumbnail = createThumbnail(for: destinationURL)
            
            // UI 업데이트는 메인 스레드에서
            DispatchQueue.main.async { [weak self] in
                // 세션 저장
                SessionManager.shared.saveSession(session)
                
                // 최근 가져온 목록에 추가
                if let thumbnail = thumbnail {
                    self?.recentImports.insert(
                        ImportedVideoInfo(url: destinationURL, date: Date(), thumbnail: thumbnail),
                        at: 0
                    )
                    
                    // 최근 목록을 5개로 제한
                    if self?.recentImports.count ?? 0 > 5 {
                        self?.recentImports.removeLast()
                    }
                }
                
                self?.isLoading = false
                self?.showSuccessAlert = true
            }
        } catch {
            DispatchQueue.main.async { [weak self] in
                self?.error = "비디오 저장 오류: \(error.localizedDescription)"
                self?.isLoading = false
            }
        }
    }
    
    private func createThumbnail(for videoURL: URL) -> UIImage? {
        let asset = AVAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // 비디오의 1초 지점에서 썸네일 생성
        let time = CMTime(seconds: 1, preferredTimescale: 60)
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("썸네일 생성 실패: \(error)")
            return nil
        }
    }
}
