//
//  ImageModel.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import Foundation

struct ImageModel: Decodable {
    let id: Int
    let name: String
    let url: String
    let thumbnailUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id, name, url, formats
    }
    
    enum FormatsKeys: String, CodingKey {
        case thumbnail
    }
    
    enum ThumbnailKeys: String, CodingKey {
        case url
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        url = try container.decode(String.self, forKey: .url)
        
        if let formats = try? container.nestedContainer(keyedBy: FormatsKeys.self, forKey: .formats),
           let thumbnail = try? formats.nestedContainer(keyedBy: ThumbnailKeys.self, forKey: .thumbnail),
           let thumbnailUrl = try? thumbnail.decode(String.self, forKey: .url) {
            self.thumbnailUrl = thumbnailUrl
        } else {
            self.thumbnailUrl = nil
        }
    }
}
