//
//  RecordingTimerView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct RecordingTimerView: View {
    let recordingTime: TimeInterval
    
    var formattedTime: String {
        let minutes = Int(recordingTime) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
            
            Text(formattedTime)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(16)
    }
}
