//
//  ContentView.swift
//  UploadingFilesExercise
//
//  Created by João Dall Agnol on 08/02/23.
//

import SwiftUI
import CoreData
import MobileCoreServices
import UniformTypeIdentifiers

enum Destination: Hashable {
    case patiensListView
}

struct ContentView: View {
    
    //to - do View model
    @Environment(\.managedObjectContext) var moc
    
    @State private var path: [Destination] = []
    @State var showFileChooser = false
    @State var fileURL: URL?
    @State private var fileName: String = ""
    @State private var patientName: String = ""
    @State private var examToUpload: Data?
    
    
    
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
                
                //to-do file uploeader
                Button {
                    showFileChooser = true
                } label: {
                    Text("File Picker")
                }
                
                PDFKitRepresentedView(examToUpload ?? Data())
                
                Spacer()
                Group {
                    Button {
                        print("upload button tapped")
                        let patient = Patient(context: moc)
                        
                        patient.id = UUID()
                        patient.name = "Exame \(self.fileName) de \(self.patientName)"
                        patient.exam = self.examToUpload
                        
                        try? moc.save()
                        
                    } label: {
                        Text("Upload")
                    }
                    
                    Divider()
                    
                    Button {
                        self.fileName = ""
                        self.patientName = ""
                        path.append(.patiensListView)
                    } label: {
                        Text("All Patients")
                    }
                }
                
                NavigationLink(value: Destination.patiensListView) {
                    EmptyView()
                }
                .navigationDestination(for: Destination.self) {
                    switch $0 {
                    case .patiensListView:
                        PatientsListView()
                    }

                }
                .padding()
            }
        }
        .fileImporter(isPresented: $showFileChooser, allowedContentTypes: [.pdf], allowsMultipleSelection: false) { result in
            importFile(result)
        }
    }
    
    func importFile(_ res: Result<[URL], Error>) {
        do{
            let fileUrlArray = try res.get()
            let fileUrl = fileUrlArray[0]
            print(fileUrl)
            //
            guard fileUrl.startAccessingSecurityScopedResource() else { return }
            
            let fileData = try Data(contentsOf: fileUrl)
            
            self.examToUpload = fileData
            
            fileUrl.stopAccessingSecurityScopedResource()
        } catch {
            print ("error reading")
            print (error.localizedDescription)
        }
    }
    
}
