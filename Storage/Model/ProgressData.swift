//
//  Untitled.swift
//  Storage
//
//  Created by Максим Герасимов on 01.12.2024.
//

import Foundation
import Combine

struct ProgressData {
    let progress: Float
    let data: Data?
}

extension URLSession {
    func dataTaskWithProgressPublisher(for url: URL) -> AnyPublisher<ProgressData, Error> {
        let subject = PassthroughSubject<ProgressData, Error>()
        let task = self.dataTask(with: url) { data, _, error in
            if let error = error {
                subject.send(completion: .failure(error))
            } else if let data = data {
                subject.send(ProgressData(progress: 1.0, data: data))
                subject.send(completion: .finished)
            }
        }
        
        task.resume()
        return subject.eraseToAnyPublisher()
    }
}
