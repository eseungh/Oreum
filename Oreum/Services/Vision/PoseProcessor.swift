//
//  PoseProcessor.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation
import UIKit
import CoreMotion

// 동작 유형 열거형
enum ClimbingMovementType: String, Codable {
    case reach = "리치" // 손을 뻗는 동작
    case pull = "당기기" // 상체를 당기는 동작
    case push = "밀기" // 다리로 밀어내는 동작
    case rest = "휴식" // 정지 상태
    case flag = "플래그" // 다리를 교차시키는 동작
    case dyno = "다이노" // 점프하는 동작
    case unknown = "알 수 없음"
}

// 움직임 분석 결과 구조체
struct MovementAnalysis {
    let timestamp: TimeInterval
    let movementType: ClimbingMovementType
    let confidence: Float // 분석 신뢰도
    let jointAngles: [String: Float] // 주요 관절 각도
    let bodyPosition: CGPoint // 몸의 중심 위치
}

class PoseProcessor {
    // 최근 포즈 기록 (동작 분석을 위한)
    private var recentPoses: [PoseObservation] = []
    private let maxPoseHistory = 30 // 약 1초 분량 (30fps 기준)
    
    // 분석 결과 콜백
    var onMovementDetected: ((MovementAnalysis) -> Void)?
    
    // 동작 감지 임계값
    private let movementThreshold: CGFloat = 0.05
    private let dynoCriterion: CGFloat = 0.2 // 다이노 동작 감지 임계값
    
    // 포즈 데이터 처리
    func processPose(_ pose: PoseObservation) {
        // 최근 포즈 목록 업데이트
        recentPoses.append(pose)
        if recentPoses.count > maxPoseHistory {
            recentPoses.removeFirst()
        }
        
        // 최소 필요 포즈 수를 충족하면 분석 시작
        if recentPoses.count >= 5 {
            analyzeMovement()
        }
    }
    
    // 동작 분석
    private func analyzeMovement() {
        guard let latestPose = recentPoses.last else { return }
        
        // 1. 주요 관절 각도 계산
        let jointAngles = calculateJointAngles(for: latestPose)
        
        // 2. 몸의 중심 위치 계산
        let bodyPosition = calculateBodyCenter(for: latestPose)
        
        // 3. 최근 포즈들의 움직임 분석
        let movementType = detectMovementType()
        
        // 4. 분석 결과 생성
        let analysis = MovementAnalysis(
            timestamp: latestPose.timestamp,
            movementType: movementType,
            confidence: calculateConfidence(for: movementType),
            jointAngles: jointAngles,
            bodyPosition: bodyPosition
        )
        
        // 결과 전달
        onMovementDetected?(analysis)
    }
    
    // 관절 각도 계산
    private func calculateJointAngles(for pose: PoseObservation) -> [String: Float] {
        var angles: [String: Float] = [:]
        
        // 오른쪽 팔꿈치 각도
        if let shoulder = pose.joint(named: "right_shoulder"),
           let elbow = pose.joint(named: "right_elbow"),
           let wrist = pose.joint(named: "right_wrist") {
            let angle = Float(angleBetweenThreePoints(shoulder.point, elbow.point, wrist.point))
            angles["right_elbow"] = angle
        }
        
        // 왼쪽 팔꿈치 각도
        if let shoulder = pose.joint(named: "left_shoulder"),
           let elbow = pose.joint(named: "left_elbow"),
           let wrist = pose.joint(named: "left_wrist") {
            let angle = Float(angleBetweenThreePoints(shoulder.point, elbow.point, wrist.point))
            angles["left_elbow"] = angle
        }
        
        // 오른쪽 무릎 각도
        if let hip = pose.joint(named: "right_hip"),
           let knee = pose.joint(named: "right_knee"),
           let ankle = pose.joint(named: "right_ankle") {
            let angle = Float(angleBetweenThreePoints(hip.point, knee.point, ankle.point))
            angles["right_knee"] = angle
        }
        
        // 왼쪽 무릎 각도
        if let hip = pose.joint(named: "left_hip"),
           let knee = pose.joint(named: "left_knee"),
           let ankle = pose.joint(named: "left_ankle") {
            let angle = Float(angleBetweenThreePoints(hip.point, knee.point, ankle.point))
            angles["left_knee"] = angle
        }
        
        return angles
    }
    
    // 세 점 사이의 각도 계산 (중간점이 꼭지점)
    private func angleBetweenThreePoints(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint) -> CGFloat {
        let vector1 = CGVector(dx: p1.x - p2.x, dy: p1.y - p2.y)
        let vector2 = CGVector(dx: p3.x - p2.x, dy: p3.y - p2.y)
        
        let dot = vector1.dx * vector2.dx + vector1.dy * vector2.dy
        let magnitude1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let magnitude2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)
        
        let cosAngle = dot / (magnitude1 * magnitude2)
        
        // Clamp to handle floating point errors
        let clampedCosAngle = max(-1.0, min(1.0, cosAngle))
        
        return acos(clampedCosAngle) * 180 / .pi // 라디안에서 도로 변환
    }
    
    // 몸의 중심 계산
    private func calculateBodyCenter(for pose: PoseObservation) -> CGPoint {
        if let root = pose.joint(named: "root") {
            return root.point
        } else if let leftHip = pose.joint(named: "left_hip"),
                  let rightHip = pose.joint(named: "right_hip") {
            // 양 엉덩이의 중간점
            return CGPoint(
                x: (leftHip.point.x + rightHip.point.x) / 2,
                y: (leftHip.point.y + rightHip.point.y) / 2
            )
        } else {
            // 기본값
            return CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    // 동작 유형 감지
    private func detectMovementType() -> ClimbingMovementType {
        guard recentPoses.count >= 5 else { return .unknown }
        
        // 최근 5개 포즈만 사용
        let posesToAnalyze = Array(recentPoses.suffix(5))
        let latestPose = posesToAnalyze.last!
        
        // 다이노(점프) 감지 - 몸의 중심이 급격히 상승
        if detectDynoMovement(in: posesToAnalyze) {
            return .dyno
        }
        
        // 팔 동작 분석
        if detectReachMovement(in: posesToAnalyze) {
            return .reach
        }
        
        // 당기기 동작 - 팔꿈치 각도가 감소하는 경우
        if detectPullMovement(in: posesToAnalyze) {
            return .pull
        }
        
        // 밀기 동작 - 다리의 각도 변화가 급격한 경우
        if detectPushMovement(in: posesToAnalyze) {
            return .push
        }
        
        // 플래그 동작 - 다리가 교차되는 경우
        if detectFlagMovement(for: latestPose) {
            return .flag
        }
        
        // 움직임이 적으면 휴식 상태로 간주
        if movementIsMinimal(in: posesToAnalyze) {
            return .rest
        }
        
        return .unknown
    }
    
    // 다이노(점프) 동작 감지
    private func detectDynoMovement(in poses: [PoseObservation]) -> Bool {
        guard poses.count >= 3 else { return false }
        
        // y축 위치 변화 확인 (작은 값이 화면 위쪽)
        let positions = poses.compactMap { pose -> CGPoint? in
            if let root = pose.joint(named: "root") {
                return root.point
            } else if let leftHip = pose.joint(named: "left_hip"),
                      let rightHip = pose.joint(named: "right_hip") {
                return CGPoint(
                    x: (leftHip.point.x + rightHip.point.x) / 2,
                    y: (leftHip.point.y + rightHip.point.y) / 2
                )
            }
            return nil
        }
        
        guard positions.count >= 3 else { return false }
        
        // 연속적인 프레임 간의 상승 검사
        for i in 1..<positions.count {
            let prevY = positions[i-1].y
            let currY = positions[i].y
            
            // y 좌표가 급격히 감소(=화면에서 위로 올라감)
            if prevY - currY > dynoCriterion {
                return true
            }
        }
        
        return false
    }
    
    // 리치(손 뻗기) 동작 감지
    private func detectReachMovement(in poses: [PoseObservation]) -> Bool {
        guard poses.count >= 3 else { return false }
        
        // 손목 위치 변화 확인
        let leftWristPositions = poses.compactMap { $0.joint(named: "left_wrist")?.point }
        let rightWristPositions = poses.compactMap { $0.joint(named: "right_wrist")?.point }
        
        // 충분한 데이터가 있는지 확인
        guard leftWristPositions.count >= 3 || rightWristPositions.count >= 3 else {
            return false
        }
        
        // 왼손 리치 검사
        if leftWristPositions.count >= 3 {
            let first = leftWristPositions.first!
            let last = leftWristPositions.last!
            let distance = hypot(last.x - first.x, last.y - first.y)
            
            if distance > movementThreshold * 3 { // 리치는 좀 더 큰 움직임
                return true
            }
        }
        
        // 오른손 리치 검사
        if rightWristPositions.count >= 3 {
            let first = rightWristPositions.first!
            let last = rightWristPositions.last!
            let distance = hypot(last.x - first.x, last.y - first.y)
            
            if distance > movementThreshold * 3 {
                return true
            }
        }
        
        return false
    }
    
    // 당기기 동작 감지
    private func detectPullMovement(in poses: [PoseObservation]) -> Bool {
        guard poses.count >= 3 else { return false }
        
        // 팔꿈치 각도 변화 추적
        var leftElbowAngles: [Float] = []
        var rightElbowAngles: [Float] = []
        
        for pose in poses {
            if let shoulder = pose.joint(named: "left_shoulder"),
               let elbow = pose.joint(named: "left_elbow"),
               let wrist = pose.joint(named: "left_wrist") {
                let angle = Float(angleBetweenThreePoints(shoulder.point, elbow.point, wrist.point))
                leftElbowAngles.append(angle)
            }
            
            if let shoulder = pose.joint(named: "right_shoulder"),
               let elbow = pose.joint(named: "right_elbow"),
               let wrist = pose.joint(named: "right_wrist") {
                let angle = Float(angleBetweenThreePoints(shoulder.point, elbow.point, wrist.point))
                rightElbowAngles.append(angle)
            }
        }
        
        // 각도 감소 확인 (팔을 구부리는 동작)
        if leftElbowAngles.count >= 3 && (leftElbowAngles.first! - leftElbowAngles.last!) > 20 {
            return true
        }
        
        if rightElbowAngles.count >= 3 && (rightElbowAngles.first! - rightElbowAngles.last!) > 20 {
            return true
        }
        
        return false
    }
    
    // 밀기 동작 감지
    private func detectPushMovement(in poses: [PoseObservation]) -> Bool {
        guard poses.count >= 3 else { return false }
        
        // 무릎 각도 변화 추적
        var leftKneeAngles: [Float] = []
        var rightKneeAngles: [Float] = []
        
        for pose in poses {
            if let hip = pose.joint(named: "left_hip"),
               let knee = pose.joint(named: "left_knee"),
               let ankle = pose.joint(named: "left_ankle") {
                let angle = Float(angleBetweenThreePoints(hip.point, knee.point, ankle.point))
                leftKneeAngles.append(angle)
            }
            
            if let hip = pose.joint(named: "right_hip"),
               let knee = pose.joint(named: "right_knee"),
               let ankle = pose.joint(named: "right_ankle") {
                let angle = Float(angleBetweenThreePoints(hip.point, knee.point, ankle.point))
                rightKneeAngles.append(angle)
            }
        }
        
        // 각도 증가 확인 (다리를 펴는 동작)
        if leftKneeAngles.count >= 3 && (leftKneeAngles.last! - leftKneeAngles.first!) > 20 {
            return true
        }
        
        if rightKneeAngles.count >= 3 && (rightKneeAngles.last! - rightKneeAngles.first!) > 20 {
            return true
        }
        
        return false
    }
    
    // 플래그 동작 감지 (다리 교차)
    private func detectFlagMovement(for pose: PoseObservation) -> Bool {
        guard let leftAnkle = pose.joint(named: "left_ankle"),
              let rightAnkle = pose.joint(named: "right_ankle"),
              let leftHip = pose.joint(named: "left_hip"),
              let rightHip = pose.joint(named: "right_hip") else {
            return false
        }
        
        // 발목의 x좌표 교차 확인
        let leftAnkleX = leftAnkle.point.x
        let rightAnkleX = rightAnkle.point.x
        let leftHipX = leftHip.point.x
        let rightHipX = rightHip.point.x
        
        // 왼쪽 엉덩이는 왼쪽에 있지만 왼쪽 발목이 오른쪽에 있는 경우
        let leftCross = leftHipX < rightHipX && leftAnkleX > rightAnkleX
        
        // 오른쪽 엉덩이는 오른쪽에 있지만 오른쪽 발목이 왼쪽에 있는 경우
        let rightCross = rightHipX > leftHipX && rightAnkleX < leftAnkleX
        
        return leftCross || rightCross
    }
    
    // 전반적인 움직임이 적은지 확인
    private func movementIsMinimal(in poses: [PoseObservation]) -> Bool {
        guard poses.count >= 3 else { return true }
        
        let first = poses.first!
        let last = poses.last!
        
        // 주요 관절 움직임 검사
        let jointsToCheck = ["right_wrist", "left_wrist", "right_ankle", "left_ankle"]
        
        for jointName in jointsToCheck {
            if let firstJoint = first.joint(named: jointName),
               let lastJoint = last.joint(named: jointName) {
                let distance = hypot(lastJoint.point.x - firstJoint.point.x, lastJoint.point.y - firstJoint.point.y)
                if distance > movementThreshold {
                    return false
                }
            }
        }
        
        return true
    }
    
    // 동작 분석 신뢰도 계산
    private func calculateConfidence(for movementType: ClimbingMovementType) -> Float {
        // 이 메서드는 필요에 따라 더 복잡하게 구현할 수 있습니다
        switch movementType {
        case .unknown:
            return 0.3
        case .rest:
            return 0.9
        case .dyno:
            return 0.8
        default:
            return 0.7
        }
    }
    
    // 이전 동작 기록 초기화
    func reset() {
        recentPoses.removeAll()
    }
}
