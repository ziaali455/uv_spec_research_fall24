import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate
import UIKit
import ImageIO
import PhotosUI

struct ChromaticityView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Processing Image...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else {
                if let image = viewModel.inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                
                PhotosPicker(selection: $viewModel.selectedItem, matching: .images) {
                    Text("Select Photo")
                }
                .padding()
                .onChange(of: viewModel.selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self),
                           let uiImage = UIImage(data: data) {
                            viewModel.inputImage = uiImage
                            viewModel.processImage(imageData: data)
                        } else {
                            print("Failed to load image data.")
                        }
                    }
                }
                
                if let chromaticity = viewModel.chromaticity, let stdDev = viewModel.chromaticityStdDev {
                    Text("Chromaticity: x = \(chromaticity.x), y = \(chromaticity.y)")
                    Text("Std Dev: x = \(stdDev.x), y = \(stdDev.y)")
                }
                
                if let avgXYZ = viewModel.avgXYZValues {
                    Text("Average XYZ Values:")
                        .fontWeight(.bold)
                        .padding(.top, 4)
                    Text("X = \(avgXYZ.x)")
                    Text("Y = \(avgXYZ.y)")
                    Text("Z = \(avgXYZ.z)")
                }
            }
        }
    }
}
