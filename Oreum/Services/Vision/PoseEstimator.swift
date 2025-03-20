//
//  PoseEstimator.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import Vision
import UIKit
import AVFoundation

class PoseEstimator {
    // 싱글톤 인스턴스
    static let shared = PoseEstimator()
    
    // Vision 포즈 추정을 위한 요청 객체
    private var poseRequest = VNDetectHumanBodyPoseRequest()
    
    // 콜백 메서드 타입 정의
    typealias PoseEstimationHandler = (VNHumanBodyPoseObservation?) -> Void
    
    private init() {
        // 초기 설정이 필요한 경우 여기에 추가
    }
    
    // 이미지에서 포즈 추정
    func detectPose(from image: CGImage, completion: @escaping PoseEstimationHandler) {
        let requestHandler = VNImageRequestHandler(cgImage: image)
        
        do {
            try requestHandler.perform([poseRequest])
            
            // 결과 처리
            if let observation = poseRequest.results?.first {
                completion(observation)
            } else {
                completion(nil)
            }
        } catch {
            print("포즈 추정 오류: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    func detectPose(from pixelBuffer: CVPixelBuffer, completion: @escaping PoseEstimationHandler) {
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up)
        
        do {
            try requestHandler.perform([poseRequest])
            
            if let observation = poseRequest.results?.first {
                completion(observation)
            } else {
                completion(nil)
            }
        } catch {
            print("비디오 프레임 포즈 추정 오류: \(error.localizedDescription)")
            completion(nil)
        }
    }

    // 관절 위치 추출 메서드
    func getJointsPositions(from observation: VNHumanBodyPoseObservation) -> [VNHumanBodyPoseObservation.JointName: CGPoint] {
        var joints: [VNHumanBodyPoseObservation.JointName: CGPoint] = [:]
        
        // 주요 관절들 정의
        let jointNames: [VNHumanBodyPoseObservation.JointName] = [
            .nose, .neck, .rightShoulder, .rightElbow, .rightWrist,
            .leftShoulder, .leftElbow, .leftWrist, .root,
            .rightHip, .rightKnee, .rightAnkle,
            .leftHip, .leftKnee, .leftAnkle
        ]
        
        for jointName in jointNames {
            do {
                let recognizedPoint = try observation.recognizedPoint(jointName)
                
                if recognizedPoint.confidence > 0.3 {
                    let point = CGPoint(x: recognizedPoint.x, y: 1 - recognizedPoint.y)
                    joints[jointName] = point
                }
            } catch {
                continue
            }
        }
        
        return joints
    }

    // UIImage에서 포즈 추정 (편의 메서드)
    func detectPose(from uiImage: UIImage, completion: @escaping PoseEstimationHandler) {
        guard let cgImage = uiImage.cgImage else {
            completion(nil)
            return
        }
        
        detectPose(from: cgImage, completion: completion)
    }
}
