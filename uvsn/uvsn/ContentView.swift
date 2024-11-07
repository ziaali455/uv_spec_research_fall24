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




