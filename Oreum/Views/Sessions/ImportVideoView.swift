//
//  ImportVideoView.swift
//  Oreum
//
//  Created by Seungho on 3/20/25.
//

import SwiftUI
import PhotosUI

struct ImportVideoView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = ImportVideoViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("비디오 불러오는 중...")
                } else if let error = viewModel.error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)
                        
                        Text("비디오를 불러올 수 없습니다")
                            .font(.title2)
                        
                        Text(error)
                            .foregroundColor(.gray)
                        
                        Button("다시 시도") {
                            viewModel.resetState()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .padding()
                } else {
                    Button(action: {
                        viewModel.showPhotoPicker = true
                    }) {
                        VStack(spacing: 15) {
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 60))
                                .foregroundColor(.blue)
                            
                            Text("갤러리에서 비디오 선택")
                                .font(.headline)
                            
                            Text("클라이밍 세션 영상을 선택해주세요")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                                .background(Color.blue.opacity(0.05))
                        )
                        .padding()
                    }
                    
                    Spacer()
                    
                    // 최근 불러온 비디오 목록 (옵션)
                    if !viewModel.recentImports.isEmpty {
                        VStack(alignment: .leading) {
                            Text("최근 불러온 비디오")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    ForEach(viewModel.recentImports) { importInfo in
                                        VStack {
                                            if let thumbnail = importInfo.thumbnail {
                                                Image(uiImage: thumbnail)
                                                    .resizable()
                                                    .aspectRatio(contentMode: .fill)
                                                    .frame(width: 120, height: 80)
                                                    .cornerRadius(8)
                                            } else {
                                                Rectangle()
                                                    .fill(Color.gray.opacity(0.3))
                                                    .frame(width: 120, height: 80)
                                                    .cornerRadius(8)
                                            }
                                            
                                            Text(importInfo.date, style: .date)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("비디오 가져오기")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PHPickerViewController.View(
                    selectionLimit: 1,
                    filter: .videos,
                    onSelection: viewModel.handlePickedVideos
                )
            }
            .alert(isPresented: $viewModel.showSuccessAlert) {
                Alert(
                    title: Text("비디오 가져오기 성공"),
                    message: Text("클라이밍 세션이 성공적으로 추가되었습니다."),
                    dismissButton: .default(Text("확인")) {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }
}

// PhotosUI의 PHPickerViewController용 SwiftUI 래퍼
extension PHPickerViewController {
    struct View: UIViewControllerRepresentable {
        let selectionLimit: Int
        let filter: PHPickerFilter
        let onSelection: ([PHPickerResult]) -> Void
        
        func makeUIViewController(context: Context) -> PHPickerViewController {
            var configuration = PHPickerConfiguration()
            configuration.selectionLimit = selectionLimit
            configuration.filter = filter
            
            let controller = PHPickerViewController(configuration: configuration)
            controller.delegate = context.coordinator
            return controller
        }
        
        func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
        
        func makeCoordinator() -> Coordinator {
            Coordinator(onSelection: onSelection)
        }
        
        class Coordinator: NSObject, PHPickerViewControllerDelegate {
            let onSelection: ([PHPickerResult]) -> Void
            
            init(onSelection: @escaping ([PHPickerResult]) -> Void) {
                self.onSelection = onSelection
            }
            
            func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
                picker.dismiss(animated: true)
                onSelection(results)
            }
        }
    }
}
