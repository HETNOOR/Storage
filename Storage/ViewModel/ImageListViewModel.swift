//
//  ImageListViewModel.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import Foundation
import Combine

final class ImageListViewModel: ObservableObject {
    @Published var cellViewModels: [ImageCellViewModel] = []
    private var cancellables = Set<AnyCancellable>()
    private let imageService = ImageService()
    
    func fetchImages() {
        imageService.fetchImages()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Ошибка загрузки изображений: \(error)")
                }
            }, receiveValue: { [weak self] images in
                guard let self = self else { return }
                
                self.cellViewModels = images.map { image in
                    let existingViewModel = self.cellViewModels.first(where: { $0.image.id == image.id })
                    return existingViewModel ?? ImageCellViewModel(image: image, imageService: self.imageService)
                }
            })
            .store(in: &cancellables)
    }
}

