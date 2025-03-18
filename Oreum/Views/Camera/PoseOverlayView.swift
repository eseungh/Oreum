//
//  PoseOverlayView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI
import UIKit

struct PoseOverlayView: UIViewRepresentable {
    var pose: PoseObservation?
    let frame: CGRect
    let lineWidth: CGFloat = 5.0
    let jointRadius: CGFloat = 7.0
    
    // 관절 연결 정의
    let connections: [(from: String, to: String)] = [
        ("neck", "left_shoulder"),
        ("neck", "right_shoulder"),
        ("left_shoulder", "left_elbow"),
        ("left_elbow", "left_wrist"),
        ("right_shoulder", "right_elbow"),
        ("right_elbow", "right_wrist"),
        ("neck", "root"),
        ("root", "left_hip"),
        ("root", "right_hip"),
        ("left_hip", "left_knee"),
        ("left_knee", "left_ankle"),
        ("right_hip", "right_knee"),
        ("right_knee", "right_ankle")
    ]
    
    // 색상 정의 (신체 부위에 따라 다른 색상 사용)
    func colorForJoint(_ name: String) -> UIColor {
        if name.contains("right") {
            return UIColor.systemGreen.withAlphaComponent(0.9)
        } else if name.contains("left") {
            return UIColor.systemBlue.withAlphaComponent(0.9)
        } else {
            return UIColor.systemOrange.withAlphaComponent(0.9)
        }
    }
    
    // UIView 생성
    func makeUIView(context: Context) -> UIView {
        let view = PoseView()
        view.backgroundColor = .clear
        view.frame = frame
        view.pose = pose
        view.connections = connections
        view.lineWidth = lineWidth
        view.jointRadius = jointRadius
        view.colorForJoint = colorForJoint
        return view
    }
    
    // UIView 업데이트
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let poseView = uiView as? PoseView else { return }
        poseView.pose = pose
        poseView.frame = frame
        poseView.setNeedsDisplay()
    }
    
    // 포즈를 그리는 내부 뷰 클래스
    class PoseView: UIView {
        var pose: PoseObservation?
        var connections: [(from: String, to: String)] = []
        var lineWidth: CGFloat = 5.0
        var jointRadius: CGFloat = 7.0
        var colorForJoint: ((String) -> UIColor)? = nil
        
        // 최소 신뢰도 임계값
        let confidenceThreshold: Float = 0.3
        
        override func draw(_ rect: CGRect) {
            super.draw(rect)
            
            guard let pose = pose, let context = UIGraphicsGetCurrentContext() else { return }
            
            // 좌표 변환을 위한 준비
            let viewSize = bounds.size
                        
            // 모든 연결 그리기
            for connection in connections {
                guard let jointFrom = pose.joint(named: connection.from),
                      let jointTo = pose.joint(named: connection.to),
                      jointFrom.confidence > confidenceThreshold,
                      jointTo.confidence > confidenceThreshold else {
                    continue
                }
                
                // 뷰 좌표계로 변환
                let startPoint = CGPoint(
                    x: jointFrom.point.x * viewSize.width,
                    y: jointFrom.point.y * viewSize.height
                )
                
                let endPoint = CGPoint(
                    x: jointTo.point.x * viewSize.width,
                    y: jointTo.point.y * viewSize.height
                )
                
                // 선 그리기
                context.setLineWidth(lineWidth)
                context.setStrokeColor(colorForJoint?(connection.from) ?? UIColor.white.cgColor)
                context.move(to: startPoint)
                context.addLine(to: endPoint)
                context.strokePath()
            }
            
            // 모든 관절 그리기
            for joint in pose.joints where joint.confidence > confidenceThreshold {
                // 뷰 좌표계로 변환
                let point = CGPoint(
                    x: joint.point.x * viewSize.width,
                    y: joint.point.y * viewSize.height
                )
                
                // 관절 원 그리기
                context.setFillColor(colorForJoint?(joint.jointName) ?? UIColor.white.cgColor)
                context.addEllipse(in: CGRect(
                    x: point.x - jointRadius,
                    y: point.y - jointRadius,
                    width: jointRadius * 2,
                    height: jointRadius * 2
                ))
                context.fillPath()
            }
        }
    }
}
