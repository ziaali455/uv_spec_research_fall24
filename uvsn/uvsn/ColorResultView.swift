import SwiftUI

struct ColorResultView: View {
    var colors: [[CGFloat]] // The original 2D array representing the hue matrix
    var associatedImage: UIImage? // Optional image associated with the hue data
    @State private var isLoading: Bool = true // Start in loading state

    var body: some View {
        VStack {
            // Display the associated image
            if let image = associatedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
            } else {
                Text("No Image Available")
                    .foregroundColor(.gray)
                    .padding()
            }

            Text("Hue Matrix (Compressed):")
                .font(.headline)
                .padding(.top)

            if isLoading {
                // Show loading wheel while processing
                ProgressView("Processing...")
                    .padding()
            } else {
                // Scrollable view for the hue matrix
                ScrollView(.vertical) {
                    VStack(spacing: 2) { // Reduced spacing for compactness
                        let compressedColors = compressMatrix(colors, targetRows: 10, targetCols: 10) // Compress matrix
                        ForEach(compressedColors.indices, id: \.self) { rowIndex in
                            HStack(spacing: 2) { // Reduced spacing for compactness
                                ForEach(compressedColors[rowIndex].indices, id: \.self) { hueIndex in
                                    let hue = compressedColors[rowIndex][hueIndex] // Access hue value
                                    // Show the hue value as text
                                    Text(String(format: "%.2f", hue)) // Format the hue for better readability
                                        .font(.system(size: 12)) // Set smaller font size for compactness
                                        .padding(4) // Reduced padding for a smaller appearance
                                        .frame(minWidth: 40) // Set a minimum width for better alignment
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(3) // Smaller corner radius for a compact look
                                        .id("\(rowIndex)-\(hueIndex)") // Create a unique ID based on indices
                                }
                            }
                        }
                    }
                    .padding() // Add padding around the matrix
                    .frame(maxWidth: .infinity) // Make the table fill the available width
                    .background(Color.black) // Set a background color for the table
                    .cornerRadius(10)
                    .shadow(radius: 5) // Add shadow for better visual appeal
                }
                .frame(height: 300) // Set a fixed height for the scrollable area

                // Share button to share the original hue data
                Button(action: {
                    shareHueData()
                }) {
                    Text("Share Matrix Data")
                        .font(.title2)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.top)
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Simulate some delay or when hues processing is finished
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                isLoading = false // Set to false when hues are ready
            }
        }
    }

    // Function to compress the hue matrix for display
    private func compressMatrix(_ matrix: [[CGFloat]], targetRows: Int, targetCols: Int) -> [[CGFloat]] {
        let rowCount = matrix.count
        let colCount = matrix.first?.count ?? 0

        // Calculate the ratio for downsampling
        let rowRatio = max(1, rowCount / targetRows) // Prevent division by zero
        let colRatio = max(1, colCount / targetCols) // Prevent division by zero

        var compressedMatrix: [[CGFloat]] = Array(repeating: Array(repeating: 0, count: targetCols), count: targetRows)

        for i in 0..<targetRows {
            for j in 0..<targetCols {
                // Calculate the average hue for the compressed area
                var sum: CGFloat = 0
                var count: CGFloat = 0

                for row in (i * rowRatio)..<min((i + 1) * rowRatio, rowCount) {
                    for col in (j * colRatio)..<min((j + 1) * colRatio, colCount) {
                        sum += matrix[row][col]
                        count += 1
                    }
                }
                compressedMatrix[i][j] = count > 0 ? sum / count : 0 // Avoid division by zero
            }
        }

        return compressedMatrix
    }

    // Function to share the original hue data as JSON
    private func shareHueData() {
        let jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(colors)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            // Code to share the jsonString using a share sheet
            let activityController = UIActivityViewController(activityItems: [jsonString], applicationActivities: nil)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityController, animated: true, completion: nil)
            }
        } catch {
            print("Error encoding JSON: \(error)")
        }
    }
}
