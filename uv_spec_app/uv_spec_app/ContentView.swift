import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var isShowingCamera = false
    @State private var inputImage: UIImage?
    @State private var isLoading = false // For loading animation
    @State private var commonColors: [Color] = []

    var body: some View {
        NavigationView {
            VStack {
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .padding()
                    
                    Button(action: {
                        isLoading = true
                        extractCommonColors(from: image)
                    }) {
                        Text("Get Common Colors")
                            .font(.title)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                } else {
                    Text("No image selected")
                        .foregroundColor(.gray)
                        .padding()
                }

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
                .sheet(isPresented: $isShowingCamera) {
                    ImagePicker(image: $inputImage)
                }

                // NavigationLink to show result page after loading
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

    // Function to extract the three most common colors
    private func extractCommonColors(from image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            let colors = self.processImageForColors(image)
            DispatchQueue.main.async {
                self.commonColors = colors
                self.isLoading = false
            }
        }
    }

    private func processImageForColors(_ image: UIImage) -> [Color] {
        guard let cgImage = image.cgImage else { return [] }
        
        let pixelData = cgImage.dataProvider?.data
        let data = CFDataGetBytePtr(pixelData)
        
        var colorCount: [UIColor: Int] = [:]
        
        let width = cgImage.width
        let height = cgImage.height
        
        for x in 0..<width {
            for y in 0..<height {
                let pixelInfo = ((width * y) + x) * 4
                
                let r = CGFloat(data![pixelInfo]) / 255.0
                let g = CGFloat(data![pixelInfo + 1]) / 255.0
                let b = CGFloat(data![pixelInfo + 2]) / 255.0
                
                let color = UIColor(red: r, green: g, blue: b, alpha: 1.0)
                
                colorCount[color, default: 0] += 1
            }
        }
        
        // Sort colors by frequency
        let sortedColors = colorCount.sorted { $0.value > $1.value }
        let topColors = sortedColors.prefix(3).map { $0.key }
        
        // Convert UIColor to SwiftUI Color
        return topColors.map { Color($0) }
    }
}

struct ColorResultView: View {
    var colors: [Color]

    var body: some View {
        VStack {
            Text("Common Colors:")
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
