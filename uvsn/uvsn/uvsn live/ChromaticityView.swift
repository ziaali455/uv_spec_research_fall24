import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate
import UIKit
import ImageIO
import PhotosUI
import SwiftUI

import SwiftUI
import PhotosUI
import UIKit

struct ChromaticityView: View {
    @ObservedObject var viewModel: MainViewModel
    @State private var showImagePicker = false
    @State private var showCamera = false  // A state to control showing the camera view
    
    var body: some View {
        ScrollView {  // Make the whole view scrollable
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

                    // Image Picker or Camera Picker Button
                    HStack {
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
                        
                        Button("Take Photo") {
                            showCamera = true  // Show the camera when the button is tapped
                        }
                        .padding()
                    }

                    // Chromaticity Results
                    if let chromaticity = viewModel.chromaticity, let stdDev = viewModel.chromaticityStdDev {
                        Text("Chromaticity: r = \(chromaticity.x), g = \(chromaticity.y)")
                        Text("Std Dev: x = \(stdDev.x), y = \(stdDev.y)")
                    }

                    // Average XYZ Values
                    if let avgXYZ = viewModel.avgXYZValues {
                        Text("Average XYZ Values:")
                            .fontWeight(.bold)
                            .padding(.top, 4)
                        Text("X = \(avgXYZ.x)")
                        Text("Y = \(avgXYZ.y)")
                        Text("Z = \(avgXYZ.z)")
                    }

                    // Chromaticity Scatter Plot
                    if let chromaticity = viewModel.chromaticity {
                        ChromaticityPlot(chromaticity: chromaticity)
                            .frame(height: 300)  // Adjust the plot size as needed
                            .padding(.top)
                    }
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                viewModel.inputImage = image
                if let data = image.jpegData(compressionQuality: 1.0) {
                    viewModel.processImage(imageData: data)
                }
                showCamera = false  // Dismiss the camera view after capturing the photo
            }
        }
    }
}

// CameraPicker using UIImagePickerController
struct CameraPicker: UIViewControllerRepresentable {
    var onImageCaptured: (UIImage) -> Void

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}


struct ChromaticityPlot: View {
    var chromaticity: (x: CGFloat, y: CGFloat)

    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height

            // Draw X (R) and Y (G) axes limited to the first quadrant
            context.stroke(Path { path in
                path.move(to: CGPoint(x: 0, y: height)) // Bottom-left corner
                path.addLine(to: CGPoint(x: width, y: height)) // X-axis (R)
            }, with: .color(.gray), lineWidth: 1)

            context.stroke(Path { path in
                path.move(to: CGPoint(x: 0, y: height)) // Bottom-left corner
                path.addLine(to: CGPoint(x: 0, y: 0)) // Y-axis (G)
            }, with: .color(.gray), lineWidth: 1)

            // Scale chromaticity values to fit within the first quadrant
            let xPosition = chromaticity.x * width // Scale x to width
            let yPosition = height - (chromaticity.y * height) // Scale y to height (invert Y-axis)

            // Draw the chromaticity point
            let circle = Path { path in
                path.addEllipse(in: CGRect(x: xPosition - 5, y: yPosition - 5, width: 10, height: 10))
            }

            context.fill(circle, with: .color(.blue))
        }
    }
}
