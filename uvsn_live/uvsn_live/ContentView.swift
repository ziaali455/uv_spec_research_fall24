import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false
    @State private var chromaticity: (x: CGFloat, y: CGFloat)?
    @State private var rgbValues: (r: Int, g: Int, b: Int)?
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                
                Button("Select Image") {
                    showingImagePicker = true
                }
                .padding()
                
                if let chromaticity = chromaticity {
                    Text("Chromaticity: x = \(chromaticity.x), y = \(chromaticity.y)")
                }
            }
            .tabItem {
                Label("Chromaticity", systemImage: "circle.grid.3x3")
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $inputImage, onImageSelected: processImage)
            }
            .tag(0)
            
            VStack {
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }
                
                Button("Select Image") {
                    showingImagePicker = true
                }
                .padding()
                
                if let rgb = rgbValues {
                    Text("RGB Values: [\(rgb.r), \(rgb.g), \(rgb.b)]")
                }
            }
            .tabItem {
                Label("RGB Values", systemImage: "paintpalette")
            }
            .tag(1)
        }
    }
    
    func processImage() {
        guard let image = inputImage else { return }
        chromaticity = calculateChromaticity(from: image)
        rgbValues = extractRGB(from: image)
    }
    
    func calculateChromaticity(from image: UIImage) -> (CGFloat, CGFloat)? {
        guard let cgImage = image.cgImage else { return nil }
        
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var X: CGFloat = 0
        var Y: CGFloat = 0
        var Z: CGFloat = 0
        
        let conversionMatrix: [[CGFloat]] = [
            [0.4887180, 0.3106803, 0.2006017],
            [0.1762044, 0.8129847, 0.0108109],
            [0.0000000, 0.0102048, 0.9897952]
        ]
        
        for i in stride(from: 0, to: pixelData.count, by: 4) {
            let r = CGFloat(pixelData[i]) / 255.0
            let g = CGFloat(pixelData[i + 1]) / 255.0
            let b = CGFloat(pixelData[i + 2]) / 255.0
            
            let linearR = pow(r, 2.2)
            let linearG = pow(g, 2.2)
            let linearB = pow(b, 2.2)
            
            let Xval = conversionMatrix[0][0] * linearR + conversionMatrix[0][1] * linearG + conversionMatrix[0][2] * linearB
            let Yval = conversionMatrix[1][0] * linearR + conversionMatrix[1][1] * linearG + conversionMatrix[1][2] * linearB
            let Zval = conversionMatrix[2][0] * linearR + conversionMatrix[2][1] * linearG + conversionMatrix[2][2] * linearB
            
            X += Xval
            Y += Yval
            Z += Zval
        }
        
        let total = X + Y + Z
        let x = X / total
        let y = Y / total
        
        return (x, y)
    }
    
    func extractRGB(from image: UIImage) -> (Int, Int, Int)? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)
        let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo
        )
        
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let r = Int(pixelData[0])
        let g = Int(pixelData[1])
        let b = Int(pixelData[2])
        
        return (r, g, b)
    }
}







struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImageSelected: () -> Void
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        var parent: ImagePicker
        
        init(parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
                parent.onImageSelected()
            }
            picker.dismiss(animated: true)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}

