//
//  ShareButton.swift
//  uvsn
//
//  Created by Ali Zia on 10/23/24.
//

import SwiftUI
struct ShareButton: View {
    var colors: [[CGFloat]] // The original 2D array of hues

    var body: some View {
        Button(action: shareMetadata) {
            Text("Share Matrix Data")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }

    private func shareMetadata() {
        guard let documentURL = createMetadataDocument(with: colors) else { return }

        let activityViewController = UIActivityViewController(activityItems: [documentURL], applicationActivities: nil)
        if let topController = UIApplication.shared.windows.first?.rootViewController {
            topController.present(activityViewController, animated: true, completion: nil)
        }
    }

    func createMetadataDocument(with colors: [[CGFloat]]) -> URL? {
        let fileName = "HueMetadata.json"
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)

        // Create the content of the document in JSON format
        var jsonArray: [[CGFloat]] = []
        for row in colors {
            jsonArray.append(row)
        }

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            try jsonData.write(to: fileURL, options: .atomic) // Write JSON data to file
            return fileURL // Return the file URL for sharing
        } catch {
            print("Error writing file: \(error)")
            return nil
        }
    }
}
