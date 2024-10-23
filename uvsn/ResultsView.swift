//
//  ResultsView.swift
//  uvsn
//
//  Created by Ali Zia on 10/11/24.
//
import SwiftUI

struct ResultsView: View {
    var body: some View {
        NavigationView {
            VStack {
                List {
                    // Table headers
                    HStack {
                        Text("Date").bold()
                        Spacer()
                        Text("Metadata").bold()
                    }
                   
                    // Table rows
                    ForEach(results) { result in
                        HStack {
                            Text(result.dateTaken, style: .date) // Format date nicely
                            Spacer()
                            Button(action: {
                                // Action when metadata button is clicked
                                print("Metadata clicked: \(result.metadata)")
                            }) {
                                Text("view")
                                    .padding()
                                    .fontWeight(.bold)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
                .navigationTitle("results")
            }
        }
        .background(Color.white)
    }
}


struct Result: Identifiable {
    let dateTaken: Date
    let metadata: String
    let id = UUID() // Ensure each result has a unique ID
}

// Initialize the array with correct types for each Result
private var results = [
    Result(dateTaken: Date(timeIntervalSince1970: 1609459200), metadata: "Sample metadata 1"),
    Result(dateTaken: Date(timeIntervalSince1970: 1612137600), metadata: "Sample metadata 2"),
    Result(dateTaken: Date(timeIntervalSince1970: 1614556800), metadata: "Sample metadata 3"),
    Result(dateTaken: Date(timeIntervalSince1970: 1617235200), metadata: "Sample metadata 4")
]
