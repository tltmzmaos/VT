//
//  PhotoData.swift
//  VirtualTourist
//
//  Created by Jongmin Lee on 9/25/20.
//

import UIKit
import CoreData

class PhotoData {
    static let sharedInstance = PhotoData()
    
    func saveImage(context: NSManagedObjectContext, photos: [PhotoResponse], parentData: Pin) {
        for photo in photos{
            let newPhoto = Photos(context: context)
            let imageURL = FlickerClient.getImageURL(farmId: String(photo.farm), serverId: photo.server, id: photo.id, secret: photo.secret)
            let data = try? Data(contentsOf: imageURL)
            newPhoto.photo = data
            newPhoto.photos = parentData
            try? context.save()
        }
    }
}
