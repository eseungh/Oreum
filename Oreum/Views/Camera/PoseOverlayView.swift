//
//  PoseOverlayView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI
import Vision

struct PoseOverlayView: View {
    let joints: [VNHumanBodyPoseObservation.JointName: CGPoint]
    let viewSize: CGSize
    
    // 관절 연결선 정의 (스켈레톤)
    private let connections: [(from: VNHumanBodyPoseObservation.JointName, to: VNHumanBodyPoseObservation.JointName)] = [
        // 몸통
        (.neck, .root),
        
        // 왼쪽 팔
        (.leftShoulder, .neck),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        
        // 오른쪽 팔
        (.rightShoulder, .neck),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        
        // 왼쪽 다리
        (.root, .leftHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle),
        
        // 오른쪽 다리
        (.root, .rightHip),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle)
    ]
    
    var body: some View {
        Canvas { context, size in
            // 캔버스 크기 스케일링 (Vision 좌표계: 0-1 -> 뷰 사이즈)
            for connection in connections {
                guard let fromPoint = joints[connection.from],
                      let toPoint = joints[connection.to] else {
                    continue
                }
                
                // 좌표 변환
                let scaledFromPoint = CGPoint(
                    x: fromPoint.x * size.width,
                    y: fromPoint.y * size.height
                )
                
                let scaledToPoint = CGPoint(
                    x: toPoint.x * size.width,
                    y: toPoint.y * size.height
                )
                
                // 관절 연결선 그리기
                let path = Path { p in
                    p.move(to: scaledFromPoint)
                    p.addLine(to: scaledToPoint)
                }
                
                context.stroke(
                    path,
                    with: .color(.green),
                    lineWidth: 3
                )
            }
            
            // 관절 포인트 그리기
            for (_, point) in joints {
                let scaledPoint = CGPoint(
                    x: point.x * size.width,
                    y: point.y * size.height
                )
                
                let circle = Path(ellipseIn: CGRect(
                    x: scaledPoint.x - 5,
                    y: scaledPoint.y - 5,
                    width: 10,
                    height: 10
                ))
                
                context.fill(
                    circle,
                    with: .color(.red)
                )
            }
        }
        .allowsHitTesting(false) // 터치 이벤트가 아래 뷰로 전달되도록
    }
}
