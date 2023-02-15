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
    
    @State var showPDF: Bool = false {
        didSet {
            if self.showPDF == false {
                selectedPatientName = ""
            }
        }
    }
    
    @State var selectedPatientName: String = ""
    @State var selectedExam: Data = Data()
    @State var isLoadedLabel: String = ""
    
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
                HStack {
                    Text(patient.name ?? "no name registered")
                    Spacer()
//                    Image(systemName: "circle")
                    Text(self.isLoadedLabel)
                    
                }
                .onTapGesture {
                    self.selectedPatientName = patient.name ?? "no name registered"
                    
                    if let exam = patient.exam {
                        self.selectedExam = exam
                        self.showPDF = true
                    } else {
                        self.showPDF = false
                        print("no PDF File to show")
                    }
                }
            }
            .onDelete(perform: delete)
        }
        .sheet(isPresented: $showPDF) {
            Text("PDF File: \(self.selectedPatientName)")
            
            
            PDFKitRepresentedView(self.selectedExam)
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
                        localPatient.recordID = cloudPatient.recordID
                        
                        if let examCKAsset = cloudPatient.value(forKey: "examAsset") as? CKAsset {
                            localPatient.exam = CKAssetToData(ckAsset: examCKAsset)
                        }
                        
                        patients.append(localPatient)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
        }
        
    }
    
    
    
    func CKAssetToData(ckAsset: CKAsset?) -> Data? {
        if ckAsset == nil { return nil }
        
        guard
            let exam = ckAsset,
            let fileURL = exam.fileURL //verificar url se voltar a deitar a foto
        else {
            return nil
        }
        
        let examData: Data
        do {
            examData = try Data(contentsOf: fileURL)
            return examData
        } catch {
            return nil
        }
//
//        do {
//            try let exam = Data(contentsOf: fileURL)
//            return exam
//        } catch {
//            return nil
//        }
        
    }
    
    
}

struct CloudPatientsListView_Previews: PreviewProvider {
    static var previews: some View {
        CloudPatientsListView()
    }
}
