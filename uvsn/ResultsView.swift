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
                        Text("Given Name").bold()
                        Spacer()
                        Text("Family Name").bold()
                        Spacer()
                        Text("E-Mail Address").bold()
                    }

                    // Table rows
                    ForEach(results) { result in
                        HStack {
                            Text(result.givenName)
                            Spacer()
                            Text(result.familyName)
                            Spacer()
                            Text(result.emailAddress)
                        }
                    }
                }
                .navigationTitle("Results")
            }
        }
    }
}

struct Result: Identifiable {
    let givenName: String
    let familyName: String
    let emailAddress: String
    let id = UUID()

    var fullName: String { givenName + " " + familyName }
}

private var results = [
    Result(givenName: "Juan", familyName: "Chavez", emailAddress: "juanchavez@icloud.com"),
    Result(givenName: "Mei", familyName: "Chen", emailAddress: "meichen@icloud.com"),
    Result(givenName: "Tom", familyName: "Clark", emailAddress: "tomclark@icloud.com"),
    Result(givenName: "Gita", familyName: "Kumar", emailAddress: "gitakumar@icloud.com")
]
