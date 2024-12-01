//
//  ImageService.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import Foundation
import Combine

final class ImageService:  NSObject, URLSessionDownloadDelegate {
    private let serverURL = "http://164.90.163.215:1337"
    private let token = "Bearer 11c211d104fe7642083a90da69799cf055f1fe1836a211aca77c72e3e069e7fde735be9547f0917e1a1000efcb504e21f039d7ff55bf1afcb9e2dd56e4d6b5ddec3b199d12a2fac122e43b4dcba3fea66fe428e7c2ee9fc4f1deaa615fa5b6a68e2975cd2f99c65a9eda376e5b6a2a3aee1826ca4ce36d645b4f59f60cf5b74a"
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    private var progressSubjects: [URL: PassthroughSubject<ProgressData, Error>] = [:]
    
    func downloadImage(from relativePath: String) -> AnyPublisher<ProgressData, Error> {
        guard let url = URL(string: serverURL + relativePath) else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        let subject = PassthroughSubject<ProgressData, Error>()
        progressSubjects[url] = subject
        
        let task = session.downloadTask(with: url)
        task.resume()
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - URLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let url = downloadTask.originalRequest?.url,
              let subject = progressSubjects[url] else { return }
        
        let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
        subject.send(ProgressData(progress: progress, data: nil))
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let url = downloadTask.originalRequest?.url,
              let subject = progressSubjects[url] else { return }
        
        do {
            let data = try Data(contentsOf: location)
            subject.send(ProgressData(progress: 1.0, data: data))
            subject.send(completion: .finished)
        } catch {
            subject.send(completion: .failure(error))
        }
        
        progressSubjects[url] = nil
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let url = task.originalRequest?.url,
              let subject = progressSubjects[url] else { return }
        
        if let error = error {
            subject.send(completion: .failure(error))
        }
        
        progressSubjects[url] = nil
    }
    
    func fetchImages() -> AnyPublisher<[ImageModel], Error> {
        guard let url = URL(string: "\(serverURL)/api/upload/files") else {
            return Fail(error: URLError(.badURL)).eraseToAnyPublisher()
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(token, forHTTPHeaderField: "Authorization")
        
        return URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [ImageModel].self, decoder: JSONDecoder())
            .mapError { $0 as Error }
            .eraseToAnyPublisher()
    }
    
}
