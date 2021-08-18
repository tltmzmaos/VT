//
//  DataController.swift
//  VirtualTourist
//
//  Created by Jongmin Lee on 9/24/20.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    var backGroundContext: NSManagedObjectContext!
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContext(){
        backGroundContext = persistentContainer.newBackgroundContext()
        
        viewContext.automaticallyMergesChangesFromParent = true
        backGroundContext.automaticallyMergesChangesFromParent = true
        
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
        backGroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
    }
    
    func load(completion: (() -> Void)? = nil){
        persistentContainer.loadPersistentStores { description, error in
            guard error == nil else {
                print("Loading error in DataController")
                return
            }
            self.configureContext()
            completion?()
        }
    }
}
