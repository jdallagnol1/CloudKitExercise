//
//  LocalDataController.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 08/02/23.
//

import Foundation
import CoreData

class LocalDataController: ObservableObject {
    let container = NSPersistentContainer(name: "Local")
    
    
    init() {
        container.loadPersistentStores(completionHandler: { description, error in
            if let error = error {
                print("error loading container: \(error)")
            }
        })
    }
}
