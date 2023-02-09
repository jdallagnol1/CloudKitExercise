//
//  PatientsListViewModel.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 08/02/23.
//

import Foundation
import SwiftUI
import PDFKit
import CoreData
import UIKit

class PatientsListViewModel: ObservableObject {
    @Environment(\.managedObjectContext) var moc
    
    init() {
//        getExams()
        
    }
    
    @FetchRequest(sortDescriptors: []) var patients: FetchedResults<Patient>
    var exams: [Data] = []
    var examTest: Data?
    

    
    func getPdfFile() -> String {
        
        return ""
    }
    
}
