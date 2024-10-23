import SwiftUI
import UIKit

// UIImage extension to add the resize functionality
extension UIImage {
    func resizeImage(targetSize: CGSize) -> UIImage {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // Determine the scale factor to maintain the aspect ratio
        let newSize: CGSize
        if widthRatio > heightRatio {
            newSize = CGSize(width: size.width * heightRatio, height: size.height * heightRatio)
        } else {
            newSize = CGSize(width: size.width * widthRatio, height: size.height * widthRatio)
        }

        // Create a graphics context for the new image size
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage ?? self // Return the resized image or original if resizing fails
    }
}

struct CaptureView: View {
    @State private var isShowingCamera = false
    @State private var inputImage: UIImage?
    @State private var isLoading = false
    @State private var commonColors: [[CGFloat]] = []
    @State private var showResults = false // New state for showing results

    var body: some View {
        NavigationView {
            VStack {
                ImageSection(inputImage: $inputImage)

                if inputImage != nil {
                    GetHueMatrixButton(
                        isLoading: $isLoading,
                        inputImage: $inputImage,
                        commonColors: $commonColors,
                        showResults: $showResults, // Pass this binding
                        extractCommonHues: processImageForHues // Pass the function
                    )
                }

                TakePhotoButton(isShowingCamera: $isShowingCamera)

                if isLoading {
                    ProgressView("Processing...")
                }
            }
            .navigationTitle("uvsn")
            .background(
                NavigationLink(
                    destination: ColorResultView(colors: commonColors),
                    isActive: $showResults, // Navigate when showResults is true
                    label: { EmptyView() }
                )
            )
        }
        .sheet(isPresented: $isShowingCamera) {
            ImagePicker(image: $inputImage, isShowingCamera: $isShowingCamera)
        }
    }

    private func processImageForHues(_ image: UIImage) -> [[CGFloat]] {
         // Resize the image to reduce the number of pixels to process
         let resizedImage = image.resizeImage(targetSize: CGSize(width: 100, height: 100)) // Adjust the target size as needed

         guard let cgImage = resizedImage.cgImage else { return [] }
         
         let pixelData = cgImage.dataProvider?.data
         let data = CFDataGetBytePtr(pixelData)
         
         let width = cgImage.width
         let height = cgImage.height

         // Initialize an empty 2D array (matrix) for the hues
         var hueMatrix: [[CGFloat]] = Array(repeating: Array(repeating: 0, count: width), count: height)

         // Loop through each pixel (RGBG format)
         for x in 0..<width {
             for y in 0..<height {
                 let pixelInfo = ((width * y) + x) * 4  // Each pixel is represented by 4 values (R, G1, B, G2)

                 let r = CGFloat(data![pixelInfo]) / 255.0      // Red channel
                 let g1 = CGFloat(data![pixelInfo + 1]) / 255.0 // Green1 channel
                 let b = CGFloat(data![pixelInfo + 2]) / 255.0  // Blue channel
                 let g2 = CGFloat(data![pixelInfo + 3]) / 255.0 // Green2 channel
                 
                 // Average the two green channels
                 let g = (g1 + g2) / 2.0
                 
                 var hue: CGFloat = 0
                 var saturation: CGFloat = 0
                 var brightness: CGFloat = 0
                 
                 // Use the averaged green value (g) in the UIColor creation
                 UIColor(red: r, green: g, blue: b, alpha: 1.0)
                     .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
                 
                 // Store the hue value in the matrix
                 hueMatrix[y][x] = hue
             }
         }
         
         return hueMatrix
     }
}




struct ImageSection: View {
    @Binding var inputImage: UIImage?

    var body: some View {
        if let image = inputImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 300)
                .padding()
        } else {
            Text("No image selected")
                .foregroundColor(.gray)
                .padding()
        }
    }
}

struct GetHueMatrixButton: View {
    @Binding var isLoading: Bool
    @Binding var inputImage: UIImage?
    @Binding var commonColors: [[CGFloat]] // Add this binding
    @Binding var showResults: Bool // Add this binding to control navigation

    var extractCommonHues: (UIImage) -> [[CGFloat]]

    var body: some View {
        Button(action: {
            if let image = inputImage {
                isLoading = true
                // Generate the 2D array of hues
                let huesMatrix = extractCommonHues(image)
                // Store the hue matrix in commonColors
                if !huesMatrix.isEmpty {
                    commonColors = huesMatrix
                    showResults = true // Trigger navigation to results
                }
                isLoading = false
            }
        }) {
            Text("Get Hue Matrix")
                .font(.title)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}


struct TakePhotoButton: View {
    @Binding var isShowingCamera: Bool

    var body: some View {
        Button(action: {
            isShowingCamera = true
        }) {
            Text("Take a Photo")
                .font(.title)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding()
    }
}




