//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Jongmin Lee on 9/23/20.
//

import Foundation

class FlickerClient {
    
    static let api = "6183345dbe393be67e8c2a5afe29c31f"
    
    enum Endpoints {
        case searchPhoto(String, String, String)
        case getPhoto(String, String, String, String)
        
        var stringValue: String {
            switch self {
            case .searchPhoto(let lat, let lon, let page):
                return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FlickerClient.api)&lat=\(lat)&lon=\(lon)&page=\(page)&per_page=21&format=json&nojsoncallback=1"
            case .getPhoto(let farmId, let serverId, let id, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func search(lat: String, lon: String, pageNum: Int, completion: @escaping ([PhotoResponse], Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.searchPhoto(lat, lon, String(pageNum)).url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion([], error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(SearchResponse.self, from: data)
                completion(responseObject.photos.photo, nil)
            } catch {
                DispatchQueue.main.async {
                    completion([], error)
                }
            }
        }
        task.resume()
    }
    
    class func getImageURL(farmId: String, serverId: String, id: String, secret: String) -> URL {
        return Endpoints.getPhoto(farmId, serverId, id, secret).url
    }
}
