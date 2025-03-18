//
//  MovementType.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import Foundation

// 클라이밍 동작 유형 (PoseProcessor.swift에서 정의한 것과 동일하게 유지)
enum ClimbingMovementType: String, Codable {
    case reach = "리치" // 손을 뻗는 동작
    case pull = "당기기" // 상체를 당기는 동작
    case push = "밀기" // 다리로 밀어내는 동작
    case rest = "휴식" // 정지 상태
    case flag = "플래그" // 다리를 교차시키는 동작
    case dyno = "다이노" // 점프하는 동작
    case unknown = "알 수 없음"
}

// 동작 분석 결과 상세 정보
struct MovementDetails: Codable {
    let type: ClimbingMovementType
    let startTime: TimeInterval
    let duration: TimeInterval
    let intensity: Float // 동작 강도
    let efficiency: Float // 동작 효율성 (0~1)
    let notes: String?
    
    // 분석 결과에 따른 색상 코드 반환
    var colorCode: String {
        switch type {
        case .reach:
            return "#4287f5" // 파란색
        case .pull:
            return "#f54242" // 빨간색
        case .push:
            return "#42f550" // 녹색
        case .rest:
            return "#a6a6a6" // 회색
        case .flag:
            return "#f5a742" // 주황색
        case .dyno:
            return "#b642f5" // 보라색
        case .unknown:
            return "#000000" // 검정색
        }
    }
}

// 세션 전체 분석 결과
struct SessionAnalysis: Codable {
    let totalDuration: TimeInterval
    let movements: [MovementDetails]
    let restPercentage: Float
    let dynamicPercentage: Float // 동적 움직임 비율
    let staticPercentage: Float // 정적 움직임 비율
    let topMovementTypes: [ClimbingMovementType] // 가장 많이 사용한 동작 타입
    let improvementSuggestions: [String]
    
    // 움직임 타입별 시간 계산
    func durationFor(type: ClimbingMovementType) -> TimeInterval {
        return movements
            .filter { $0.type == type }
            .reduce(0) { $0 + $1.duration }
    }
    
    // 총 움직임 중 특정 타입의 비율 계산
    func percentageFor(type: ClimbingMovementType) -> Float {
        let typeDuration = durationFor(type: type)
        return totalDuration > 0 ? Float(typeDuration / totalDuration) * 100 : 0
    }
}
