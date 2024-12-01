//
//  ImageCellViewModel.swift
//  Storage
//
//  Created by Максим Герасимов on 01.12.2024.
//

import Foundation
import Combine
import UIKit

final class ImageCellViewModel: ObservableObject {
    let image: ImageModel
    private let imageService: ImageService
    private var cancellables = Set<AnyCancellable>()
    
    @Published var progress: Float = 0.0
    @Published var downloadedImage: UIImage?
    @Published var isDownloading: Bool = false
    
    init(image: ImageModel, imageService: ImageService) {
        self.image = image
        self.imageService = imageService
    }
    
    func startDownload() {
        guard downloadedImage == nil else { return }
        isDownloading = true
        progress = 0.0
        
        imageService.downloadImage(from: image.url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
             
                if case .failure = completion {
                    self?.progress = 0.0
                }
            }, receiveValue: { [weak self] progressData in
                self?.progress = progressData.progress
                if let data = progressData.data, progressData.progress == 1.0 {
                    self?.downloadedImage = UIImage(data: data)
                }
            })
            .store(in: &cancellables)
    }
}

