//
//  ContentView.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 08/02/23.
//

import SwiftUI
import CoreData
import CloudKit
import MobileCoreServices
import UniformTypeIdentifiers

enum Destination: Hashable {
    case localPatientsListView, cloudPatientsListView
}

struct ContentView: View {
    
    //to - do View model
    @Environment(\.managedObjectContext) var moc
    
    private let privateDatabase = CKContainer(identifier: "iCloud.com.ExamsContainer").privateCloudDatabase
    
    @State private var path: [Destination] = []
    @State var showFileChooser = false
    @State var fileURL: URL?
    @State private var fileName: String = ""
    @State private var patientName: String = ""
    @State private var dataSelectedExam: Data?
    
    
    var body: some View {
        VStack {
            NavigationStack(path: $path) {
                Image("logo")
                    .resizable()
                    .foregroundColor(.accentColor)
                    .scaledToFit()
                
                Text("Upload File Test")
                
                TextField("File Name", text: $fileName)
                TextField("Patient Name", text: $patientName)
                
                Button {
                    showFileChooser = true
                } label: {
                    Text("File Picker")
                }
                
                PDFKitRepresentedView(dataSelectedExam ?? Data())
                
                Spacer()
                Group {
                    HStack {
                        VStack {
                            Button {
                                self.tapSaveToCoreData()
                            } label: {
                                Text("Save to CoreData")
                            }
                            
                            Divider()
                            
                            Button {
                                self.tapAllLocalPatients()
                            } label: {
                                Text("Local Patients")
                            }
                        }
                        
                        Spacer()
                        
                        VStack {
                            Button {
                                self.tapSaveToiCloud(pdfData: dataSelectedExam ?? Data())
                            } label: {
                                Text("Save to iCloud")
                            }
                            
                            Divider()
                            
                            Button {
                                self.tapAllCloudPatients()
                            } label: {
                                Text("iCloud Patients")
                            }
                        }
                    }
                }
                
                NavigationLink(value: Destination.localPatientsListView) {
                    EmptyView()
                }
                .navigationDestination(for: Destination.self) {
                    switch $0 {
                    case .localPatientsListView:
                        LocalPatientsListView()
                    case .cloudPatientsListView:
                        CloudPatientsListView()
                    }
                    
                }
                .padding()
            }
        }
        .fileImporter(isPresented: $showFileChooser, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            importFile(result)
        }
    }
    
}


extension ContentView {
    func importFile(_ res: Result<[URL], Error>) {
        do{
            let fileUrlArray = try res.get()
            let fileUrl = fileUrlArray[0]
            
            guard fileUrl.startAccessingSecurityScopedResource() else { return }
            
            let fileData = try Data(contentsOf: fileUrl)
            
            self.dataSelectedExam = fileData
            self.fileURL = fileUrl
            fileUrl.stopAccessingSecurityScopedResource()
            
        } catch {
            print ("error reading")
            print (error.localizedDescription)
        }
    }
    
    func tapAllLocalPatients() {
        path.append(.localPatientsListView)
    }
    
    func tapAllCloudPatients() {
        path.append(.cloudPatientsListView)
    }
    
    func tapSaveToCoreData() {
        print("upload button tapped")
        let patient = Patient(context: moc)
        
        patient.id = UUID()
        patient.name = "Exame \(self.fileName) de \(self.patientName)"
        patient.exam = self.dataSelectedExam
        
        try? moc.save()
    }
    
    func pdfToCKAsset(pdfData: Data) -> CKAsset? {
        if pdfData.isEmpty { return nil }
        
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString+".dat")
        do {
            try pdfData.write(to: url) //data!.writeToURL(url, options: [])
        } catch let error {
            print("Error! \(error)");
            return nil
        }
        return CKAsset(fileURL: url)
    }

    
    func tapSaveToiCloud(pdfData: Data) {
        print(#function)
        
        let record = CKRecord(recordType: "Patient")
        record.setValue("Exame \(self.fileName) de \(self.patientName)", forKey: "name")
        
        
        if self.fileURL != nil && self.dataSelectedExam != nil {
            let examAsset = pdfToCKAsset(pdfData: pdfData)
            record["examAsset"] = examAsset
        }
        
        privateDatabase.save(record) { savedRecord, error in
            print("entrou closure")
            if savedRecord != nil, error == nil {
                print("saved to iCloud")
            }
            else {
                print("some error: \(String(describing: error)) ")
            }
            
        }
        
    }
    
    
}

extension CKDatabase {
    func fetchAll(
        recordType: String, resultsLimit: Int = 100, timeout: TimeInterval = 60,
        completion: @escaping (Result<[CKRecord], Error>) -> Void
    ) {
        DispatchQueue.global().async { [unowned self] in
            let query = CKQuery(
                recordType: recordType, predicate: NSPredicate(value: true)
            )
            let semaphore = DispatchSemaphore(value: 0)
            var records = [CKRecord]()
            var error: Error?
            
            var operation = CKQueryOperation(query: query)
            operation.resultsLimit = resultsLimit
            operation.recordFetchedBlock = { records.append($0) }
            operation.queryCompletionBlock = { (cursor, err) in
                guard err == nil, let cursor = cursor else {
                    error = err
                    semaphore.signal()
                    return
                }
                let newOperation = CKQueryOperation(cursor: cursor)
                newOperation.resultsLimit = operation.resultsLimit
                newOperation.recordFetchedBlock = operation.recordFetchedBlock
                newOperation.queryCompletionBlock = operation.queryCompletionBlock
                operation = newOperation
                self.add(newOperation)
            }
            self.add(operation)
            
            _ = semaphore.wait(timeout: .now() + 60)
            
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(records))
            }
        }
    }
}
