//import SwiftUI
//import UIKit
//import AVFoundation
//
//struct CaptureView: View {
//    @State private var isShowingCamera = false
//    @State private var inputImage: UIImage?
//    @State private var isLoading = false
//    @State private var commonColors: [[CGFloat]] = []
//    @State private var showResults = false // New state for showing results
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                ImageSection(inputImage: $inputImage)
//
//                if inputImage != nil {
//                    GetHueMatrixButton(
//                        isLoading: $isLoading,
//                        inputImage: $inputImage,
//                        commonColors: $commonColors,
//                        showResults: $showResults, // Pass this binding
//                        extractCommonHues: processImageForHues // Pass the function
//                    )
//                }
//
//                TakePhotoButton(isShowingCamera: $isShowingCamera)
//
//                if isLoading {
//                    ProgressView("Processing...")
//                }
//            }
//            .navigationTitle("uvsn")
//            .background(
//                NavigationLink(
//                    destination: ColorResultView(colors: commonColors),
//                    isActive: $showResults, // Navigate when showResults is true
//                    label: { EmptyView() }
//                )
//            )
//        }
//        .sheet(isPresented: $isShowingCamera) {
//            CameraView()
//        }
//    }
//
//    // Function to process the image and extract the hue matrix
//    private func processImageForHues(_ image: UIImage) -> [[CGFloat]] {
//        // Resize the image to reduce the number of pixels to process
//        let resizedImage = image.resizeImage(targetSize: CGSize(width: 100, height: 100)) // Adjust the target size as needed
//
//        guard let cgImage = resizedImage.cgImage else {
//            print("Error: Could not get CGImage")
//            return []
//        }
//
//        let pixelData = cgImage.dataProvider?.data
//        let data = CFDataGetBytePtr(pixelData)
//
//        let width = cgImage.width
//        let height = cgImage.height
//
//        // Initialize an empty 2D array (matrix) for the hue values
//        var hueMatrix: [[CGFloat]] = Array(repeating: Array(repeating: 0, count: width), count: height)
//
//        // Loop through each pixel (RGBA format: R, G, B, A)
//        for x in 0..<width {
//            for y in 0..<height {
//                let pixelInfo = ((width * y) + x) * 4  // Each pixel is represented by 4 values (R, G, B, A)
//
//                // Safely unwrap pixel data to avoid crashes
//                guard let r = data?[pixelInfo],
//                      let g = data?[pixelInfo + 1],
//                      let b = data?[pixelInfo + 2],
//                      let a = data?[pixelInfo + 3] else {
//                    print("Error: Pixel data is invalid")
//                    continue
//                }
//
//                // Convert the RGBA values to CGFloat [0, 1] range
//                let rValue = CGFloat(r) / 255.0
//                let gValue = CGFloat(g) / 255.0
//                let bValue = CGFloat(b) / 255.0
//                let aValue = CGFloat(a) / 255.0
//
//                // Use UIColor to extract Hue from RGBA
//                var hue: CGFloat = 0
//                var saturation: CGFloat = 0
//                var brightness: CGFloat = 0
//
//                // Create a UIColor from RGBA and extract the hue component
//                UIColor(red: rValue, green: gValue, blue: bValue, alpha: aValue)
//                    .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
//
//                // Handle black pixels or low saturation pixels (hue undefined)
//                if rValue == 0 && gValue == 0 && bValue == 0 {
//                    hue = 0
//                } else if saturation < 0.1 {
//                    hue = 0
//                }
//
//                // Store the hue value in the matrix
//                hueMatrix[y][x] = hue
//            }
//        }
//
//        return hueMatrix
//    }
//
//    // Function to convert an image to RGBG format (R, G1, B, G2)
//    private func convertToRGBG(image: UIImage) -> UIImage? {
//        guard let cgImage = image.cgImage else {
//            print("Error: Could not get CGImage")
//            return nil
//        }
//
//        let width = cgImage.width
//        let height = cgImage.height
//        
//        // Create a bitmap context to hold the new RGBG image data
//        let colorSpace = CGColorSpaceCreateDeviceRGB()
//        let bitsPerComponent = 8
//        let bytesPerRow = width * 4
//        
//        guard let context = CGContext(data: nil,
//                                      width: width,
//                                      height: height,
//                                      bitsPerComponent: bitsPerComponent,
//                                      bytesPerRow: bytesPerRow,
//                                      space: colorSpace,
//                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
//            print("Error: Could not create CGContext")
//            return nil
//        }
//
//        // Draw the original image onto the new context
//        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
//
//        // Get pixel data from the context
//        guard let pixelData = context.data else {
//            print("Error: Could not retrieve pixel data")
//            return nil
//        }
//
//        let data = pixelData.bindMemory(to: UInt8.self, capacity: width * height * 4)
//
//        // Process each pixel to create the RGBG format
//        for y in 0..<height {
//            for x in 0..<width {
//                let pixelIndex = ((y * width) + x) * 4  // Each pixel is represented by 4 bytes
//
//                // Read RGBA values
//                let r = data[pixelIndex]
//                let g = data[pixelIndex + 1]
//                let b = data[pixelIndex + 2]
//                let a = data[pixelIndex + 3]
//
//                // Set the Green2 channel to be the same as Green1
//                data[pixelIndex + 1] = g
//                data[pixelIndex + 3] = g
//
//                // Update the pixel data with new RGBG values
//                data[pixelIndex] = r   // R
//                data[pixelIndex + 2] = b // B
//            }
//        }
//
//        // Create a new CGImage from the modified pixel data
//        guard let newCGImage = context.makeImage() else {
//            print("Error: Could not create new CGImage")
//            return nil
//        }
//
//        return UIImage(cgImage: newCGImage)
//    }
//}
//
//
//
