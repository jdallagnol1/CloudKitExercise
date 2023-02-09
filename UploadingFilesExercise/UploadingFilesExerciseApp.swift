//
//  UploadingFilesExerciseApp.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 08/02/23.
//

import SwiftUI

@main
struct UploadingFilesExerciseApp: App {

    @StateObject private var localDataController = LocalDataController()

    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, localDataController.container.viewContext)
        }
    }
}
