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
    private let imageService = ImageService()
    private var cancellables = Set<AnyCancellable>()
    
    func fetchImages() {
        imageService.fetchImages()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    print("Ошибка загрузки изображений: \(error)")
                }
            }, receiveValue: { [weak self] images in
                self?.cellViewModels = images.map { ImageCellViewModel(image: $0, imageService: self!.imageService) }

            })
            .store(in: &cancellables)
    }
}
