//
//  AddImageViewModel.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import Foundation
import UIKit

final class AddImageViewModel {
    var selectedImage: UIImage?
    var onImageProcessing: (() -> Void)?
    var onImageProcessingFinished: ((Bool) -> Void)?
    var onPreviewUpdated: ((UIImage?) -> Void)?
    
    private let serverURL = "http://164.90.163.215:1337"
    private let token = "Bearer 11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"
    
    func validateURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    func loadImageFromURL(_ urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                print("Ошибка загрузки URL: \(error)")
                completion(false)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(false)
                return
            }
            
            self?.preparePreviewImage(image)
            completion(true)
        }.resume()
    }
    
    func preparePreviewImage(_ image: UIImage) {
        guard let resizedImage = resizeImage(image) else { return }
        self.selectedImage = resizedImage
        self.onPreviewUpdated?(resizedImage)
    }
    
    func uploadImage(image: UIImage) {
        guard let imageData = resizeImage(image)?.jpegData(compressionQuality: 0.8) else {
            onImageProcessingFinished?(false)
            return
        }
        
        onImageProcessing?()
        
        guard let uploadURL = URL(string: "\(serverURL)/api/upload") else {
            onImageProcessingFinished?(false)
            return
        }

        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let fileName = UUID().uuidString
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(fileName).jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("Ошибка загрузки: \(error)")
                self?.onImageProcessingFinished?(false)
                return
            }

            guard let response = response as? HTTPURLResponse, response.statusCode == 200 else {
                self?.onImageProcessingFinished?(false)
                return
            }

            NotificationCenter.default.post(name: .didUploadImage, object: nil)
            self?.onImageProcessingFinished?(true)
        }.resume()
    }

    
    private func resizeImage(_ image: UIImage) -> UIImage? {
        let maxSize: CGFloat = 1_000_000 // Максимум 1 МБ
        var compression: CGFloat = 1.0
        guard var imageData = image.jpegData(compressionQuality: compression) else { return nil }
        
        while imageData.count > Int(maxSize) {
            compression -= 0.1
            guard let compressedData = image.jpegData(compressionQuality: compression) else { break }
            imageData = compressedData
        }
        
        return UIImage(data: imageData)
    }
}
