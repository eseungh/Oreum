//
//  PoseData.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import UIKit
import Vision

// 포즈 관절 데이터 구조체
struct PoseJoint {
    let point: CGPoint
    let confidence: Float
    let jointName: String
}

// 포즈 정보 구조체
struct PoseObservation {
    let joints: [PoseJoint]
    let timestamp: TimeInterval
    
    // 특정 관절 찾기 헬퍼 메서드
    func joint(named name: String) -> PoseJoint? {
        return joints.first { $0.jointName == name }
    }
}

// 움직임 분석 결과 구조체
struct MovementAnalysis {
    let timestamp: TimeInterval
    let movementType: ClimbingMovementType
    let confidence: Float // 분석 신뢰도
    let jointAngles: [String: Float] // 주요 관절 각도
    let bodyPosition: CGPoint // 몸의 중심 위치
}

// VNHumanBodyPoseObservation.JointName으로 변환하기 위한 확장
extension String {
    var asVNJointName: VNHumanBodyPoseObservation.JointName {
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
        default: return VNHumanBodyPoseObservation.JointName(rawValue: self)
        }
    }
}
