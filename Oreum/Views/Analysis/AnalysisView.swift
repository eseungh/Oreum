//
//  AnalysisView.swift
//  Oreum
//
//  Created by Seungho on 3/18/25.
//

import SwiftUI

struct AnalysisView: View {
    var body: some View {
        VStack {
            Text("분석 화면")
                .font(.largeTitle)
                .padding()
            
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 100))
                .padding()
            
            Text("이곳에 클라이밍 분석 결과가 표시될 예정입니다")
                .foregroundColor(.secondary)
                .padding()
        }
    }
}

struct AnalysisView_Previews: PreviewProvider {
    static var previews: some View {
        AnalysisView()
    }
}
