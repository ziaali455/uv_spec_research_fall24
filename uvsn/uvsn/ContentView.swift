import SwiftUI

struct CaptureView: View {
    @State private var isShowingCamera = false
    @State private var inputImage: UIImage?
    @State private var isLoading = false
    @State private var commonColors: [Color] = []

    var body: some View {
        NavigationView {
            VStack {
                ImageSection(inputImage: $inputImage)
                
                if inputImage != nil {
                    GetHuesButton(
                        isLoading: $isLoading,
                        inputImage: $inputImage,
                        extractCommonHues: extractCommonHues
                    )
                }
                
                TakePhotoButton(isShowingCamera: $isShowingCamera)
                
                NavigationLink(
                    destination: ColorResultView(colors: commonColors)
                        .onAppear {
                            isLoading = false
                        },
                    isActive: $isLoading
                ) {
                    EmptyView()
                }
            }
            .navigationTitle("uvsn")
        }
        .overlay(
            isLoading ? ProgressView("Processing...") : nil
        )
    }

    private func extractCommonHues(from image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let hues = self.processImageForHues(image)
            DispatchQueue.main.async {
                self.commonColors = hues
                self.isLoading = false
            }
        }
    }

    private func processImageForHues(_ image: UIImage) -> [Color] {
        guard let cgImage = image.cgImage else { return [] }
        
        let pixelData = cgImage.dataProvider?.data
        let data = CFDataGetBytePtr(pixelData)
        
        var hueCount: [CGFloat: Int] = [:]
        
        let width = cgImage.width
        let height = cgImage.height
        
        for x in 0..<width {
            for y in 0..<height {
                let pixelInfo = ((width * y) + x) * 4
                let r = CGFloat(data![pixelInfo]) / 255.0
                let g = CGFloat(data![pixelInfo + 1]) / 255.0
                let b = CGFloat(data![pixelInfo + 2]) / 255.0
                
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0
                UIColor(red: r, green: g, blue: b, alpha: 1.0)
                    .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
                
                hueCount[hue, default: 0] += 1
            }
        }
        
        let sortedHues = hueCount.sorted { $0.value > $1.value }
        let topHues = sortedHues.prefix(3).map { $0.key }
        
        return topHues.map { Color(hue: $0, saturation: 1.0, brightness: 1.0) }
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

struct GetHuesButton: View {
    @Binding var isLoading: Bool
    @Binding var inputImage: UIImage?

    var extractCommonHues: (UIImage) -> Void

    var body: some View {
        Button(action: {
            if let image = inputImage {
                isLoading = true
                extractCommonHues(image)
            }
        }) {
            Text("Get Common Hues")
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

struct ColorResultView: View {
    var colors: [Color]

    var body: some View {
        VStack {
            Text("Common Hues:")
                .font(.headline)
                .padding(.top)

            HStack {
                ForEach(colors, id: \.self) { color in
                    Rectangle()
                        .fill(color)
                        .frame(width: 50, height: 50)
                        .cornerRadius(5)
                }
            }
            .padding()
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }
}
