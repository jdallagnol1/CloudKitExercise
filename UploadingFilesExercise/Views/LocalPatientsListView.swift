//
//  PatientsListVIew.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 08/02/23.
//
import SwiftUI
import PDFKit
import CoreData
import UIKit

struct LocalPatientsListView: View {
    //CoreData
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var patients: FetchedResults<Patient>
    //
    @State var showPDF: Bool = false
    @State var patientName: String = ""
    
    var body: some View {
        Text("Patients stored on CoreData")
        List(patients) { patient in
            Text(patient.name ?? "no name registered")
                .onTapGesture {
                    self.showPDF = true
                    self.patientName = patient.name ?? "no name registered"
                }
        }
        .sheet(isPresented: $showPDF) {
            Text("PDF File:")
            
            PDFKitRepresentedView(getPdfFile(name: patientName))
        }
        
        Button {
            tapDeletePatientsButton()
        } label: {
            Text("Delete patients")
        }
 
    }
    
    func getPdfFile(name: String) -> Data {
        let size = patients.count
        for index in 0..<size {
            if patients[index].name == name {
                return patients[index].exam ?? Data()
            }
        }
        return Data()
    }
    
    func tapDeletePatientsButton() {
        for patient in patients {
            moc.delete(patient)
        }
    }
}


struct PatientsListView_Previews: PreviewProvider {
    static var previews: some View {
        LocalPatientsListView()
    }
}
