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

// 포즈 결과 처리를 위한 프로토콜
protocol PoseEstimatorDelegate: AnyObject {
    func poseEstimator(_ estimator: PoseEstimator, didDetectPose pose: PoseObservation)
    func poseEstimator(_ estimator: PoseEstimator, didFailWithError error: Error)
}

class PoseEstimator {
    // 포즈 추정 요청
    private let poseRequest = VNDetectHumanBodyPoseRequest()
    
    // 이미지 처리 큐
    private let processingQueue = DispatchQueue(label: "pose-processing-queue", qos: .userInitiated)
    
    // 델리게이트
    weak var delegate: PoseEstimatorDelegate?
    
    // 사용할 인식 관절 이름 (필요에 따라 조정)
    private let requiredJoints = [
        "neck",
        "right_shoulder", "right_elbow", "right_wrist",
        "left_shoulder", "left_elbow", "left_wrist",
        "root",
        "right_hip", "right_knee", "right_ankle",
        "left_hip", "left_knee", "left_ankle"
    ]
    
    // 포즈 추정을 위한 Vision 요청 구성
    init() {
        poseRequest.maximumNumberOfResults = 1 // 가장 확실한 사람 하나만 처리
    }
    
    // 이미지에서 포즈 처리
    func processImage(_ image: CVPixelBuffer, timestamp: TimeInterval) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .up)
        
        processingQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try imageRequestHandler.perform([self.poseRequest])
                
                if let observation = self.poseRequest.results?.first {
                    let pose = self.processObservation(observation, timestamp: timestamp)
                    
                    DispatchQueue.main.async {
                        self.delegate?.poseEstimator(self, didDetectPose: pose)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.poseEstimator(self, didFailWithError: error)
                }
            }
        }
    }
    
    // Core ML 포즈 관측 결과 처리
    private func processObservation(_ observation: VNHumanBodyPoseObservation, timestamp: TimeInterval) -> PoseObservation {
        var joints: [PoseJoint] = []
        
        // 각 관절 처리
        for jointName in requiredJoints {
            do {
                let jointPoint = try observation.recognizedPoint(forJointName: jointName.asVNJointName)
                let joint = PoseJoint(
                    point: CGPoint(x: jointPoint.x, y: 1 - jointPoint.y), // 좌표계 변환
                    confidence: jointPoint.confidence,
                    jointName: jointName
                )
                joints.append(joint)
            } catch {
                print("관절 인식 실패: \(jointName), 오류: \(error)")
            }
        }
        
        return PoseObservation(joints: joints, timestamp: timestamp)
    }
}

// VNRecognizedPointKey로 변환하기 위한 확장
extension String {
    var asVNRecognizedPointKey: VNRecognizedPointKey {
        switch self {
        case "nose": return .nose
        case "neck": return .neck
        case "right_shoulder": return .rightShoulder
        case "right_elbow": return .rightElbow
        case "right_wrist": return .rightWrist
        case "left_shoulder": return .leftShoulder
        case "left_elbow": return .leftElbow
        case "left_wrist": return .leftWrist
        case "root": return .root
        case "right_hip": return .rightHip
        case "right_knee": return .rightKnee
        case "right_ankle": return .rightAnkle
        case "left_hip": return .leftHip
        case "left_knee": return .leftKnee
        case "left_ankle": return .leftAnkle
        default: return VNRecognizedPointKey(rawValue: self)
        }
    }
}
