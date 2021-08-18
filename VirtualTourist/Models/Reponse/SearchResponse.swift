//
//  SearchResponse.swift
//  VirtualTourist
//
//  Created by Jongmin Lee on 9/23/20.
//

import Foundation

struct SearchResponse: Codable {
    let photos: PhotosResponse
    
    enum CodingKeys: String, CodingKey {
        case photos
    }
}

struct PhotosResponse: Codable {
    let photo: [PhotoResponse]
    
    enum CodingKeys: String, CodingKey {
        case photo
    }
}

struct PhotoResponse: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
}
