//
//  CloudPatientsListView.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 13/02/23.
//

import SwiftUI
import CloudKit

struct CloudPatientsListView: View {
    //iCloud
    private let privateDatabase = CKContainer(identifier: "iCloud.com.ExamsContainer").privateCloudDatabase
    @State var patients: [PatientLocalModel] = []
    //
    
    @State var showPDF: Bool = false
    @State var patientName: String = ""
    
    
    init() {
    }
    
    var body: some View {
        Text("Patients stored on iCloud")
        Button {
            self.fetchPatients()
        } label: {
            Text("Fetch cloud patients")
        }
        
        List {
            ForEach(patients, id: \.self) { patient in
                Text(patient.name ?? "no name registered")
                    .onTapGesture {
                        self.showPDF = true
                        self.patientName = patient.name ?? "no name registered"
                    }
            }
            .onDelete(perform: delete)
        }
        .sheet(isPresented: $showPDF) {
            Text("PDF File: \(self.patientName)")
            Text("TODOOO:")
            PDFKitRepresentedView(getPdfFile(name: patientName))
        }
        
    }
}

extension CloudPatientsListView {
    
    func delete(at offsets: IndexSet) {
        
        
        let idsToDelete = offsets.map { self.patients[$0].recordID }
        
        // schedule remote delete for selected ids
        _ = idsToDelete.compactMap { id in
            privateDatabase.delete(withRecordID: idsToDelete[0]!) { deletedRecordID, error in
                if error == nil, deletedRecordID != nil {
                    DispatchQueue.main.async {
                        self.patients.removeAll { $0.recordID == id }
                    }
                    print("deleted \(String(describing: deletedRecordID))")
                } else {
                    print(error ?? "failed delete at offsets at CloudPatientesListView")
                }
            }
            
            
        }
        
    }
    
    func fetchPatients() {
        patients = []
        DispatchQueue.main.async {
            privateDatabase.fetchAll(recordType: "Patient") { result in
                switch result {
                case .success(let fetchedPatients):
                    print("case .success as fetchPatients")
                    for cloudPatient in fetchedPatients {
                        var localPatient = PatientLocalModel()
                        localPatient.name = cloudPatient.value(forKey: "name") as? String
                        localPatient.id = cloudPatient.value(forKey: "id") as? UUID
                        localPatient.exam = cloudPatient.value(forKey: "exam") as? NSData
                        localPatient.recordID = cloudPatient.recordID
                        
                        patients.append(localPatient)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
        }
        
    }
    
    //        func deleteAllPatients() {
    //            while !patients.isEmpty {
    //                for patient in patients {
    //                    privateDatabase.delete(withRecordID: patient.recordID!) { deletedRecordID, error in
    //                        if error == nil {
    //                            print("deleted patient \(patient.name)")
    //                            patients.removeFirst()
    //                        } else {
    //                            print(error)
    //                        }
    //                    }
    //                }
    //            }
    //        }
    
    func getPdfFile(name: String) -> Data {
        let size = patients.count
        
        for index in 0..<size {
            if patients[index].name == name {
                let data = Data(referencing: patients[index].exam ?? NSData())
                return data
            }
        }
        
        return Data()
    }
}

struct CloudPatientsListView_Previews: PreviewProvider {
    static var previews: some View {
        CloudPatientsListView()
    }
}
