import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate
import UIKit
import ImageIO
import PhotosUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var inputImage: UIImage?
    @State private var showingImagePicker = false
    @State private var chromaticity: (x: CGFloat, y: CGFloat)?
    @State private var chromaticityStdDev: (x: CGFloat, y: CGFloat)?
    @State private var rgbValues: (r: Int, g: Int, b: Int)?
    @State private var metadata: String?
    @State private var xyzValues: (x: CGFloat, y: CGFloat, z: CGFloat)?
    @State private var avgXYZValues: (x: CGFloat, y: CGFloat, z: CGFloat)?
    @State private var selectedItem: PhotosPickerItem?


    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Select Photo")
                }
                .padding()
                .onChange(of: selectedItem) { newItem in
                    Task {
                        // Retrieve Image Data
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                inputImage = uiImage
                                processImage(imageData: data)
                            }
                        } else {
                            print("Failed to load image data.")
                        }
                    }
                }

                if let chromaticity = chromaticity, let stdDev = chromaticityStdDev {
                    Text("Chromaticity: x = \(chromaticity.x), y = \(chromaticity.y)")
                    Text("Std Dev: x = \(stdDev.x), y = \(stdDev.y)")
                }
                
                if let avgXYZ = avgXYZValues {
                    Text("Average XYZ Values:")
                        .fontWeight(.bold)
                        .padding(.top, 4)
                    Text("X = \(avgXYZ.x)")
                    Text("Y = \(avgXYZ.y)")
                    Text("Z = \(avgXYZ.z)")
                }
                
                if let xyz = xyzValues {
                    Text("Total XYZ Values:")
                        .fontWeight(.bold)
                        .padding(.top, 4)
                    Text("X = \(xyz.x)")
                    Text("Y = \(xyz.y)")
                    Text("Z = \(xyz.z)")
                }
            }
            .tabItem {
                Label("Chromaticity", systemImage: "circle.grid.3x3")
            }
            .tag(0)

            VStack {
                if let image = inputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 300)
                }

                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Text("Select Photo")
                }
                .padding()
                .onChange(of: selectedItem) { newItem in
                    Task {
                        // Retrieve Image Data
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                inputImage = uiImage
                                processImage(imageData: data)
                            }
                        } else {
                            print("Failed to load image data.")
                        }
                    }
                }

                if let rgb = rgbValues {
                    Text("RGB Values: [\(rgb.r), \(rgb.g), \(rgb.b)]")
                }
            }
            .tabItem {
                Label("RGB Values", systemImage: "paintpalette")
            }
            .tag(1)

            VStack {
                ScrollView {
                    if let metadata = metadata {
                        Text(metadata)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text("No metadata available")
                            .padding()
                    }
                }
            }
            .tabItem {
                Label("Metadata", systemImage: "info.circle")
            }
            .tag(2)
        }
    }

    func processImage(imageData: Data? = nil) {
        guard let image = inputImage else { return }
        let colorData = calculateChromaticity(from: image)
        chromaticity = colorData?.chromaticity.mean
        chromaticityStdDev = colorData?.chromaticity.stdDev
        xyzValues = colorData?.totalXYZ
        avgXYZValues = colorData?.avgXYZ
        rgbValues = extractRGB(from: image)
        
        // Extract metadata using the original image data when available
        if let data = imageData {
            metadata = extractMetadata(from: data)
        } else if let jpegData = image.jpegData(compressionQuality: 1.0) {
            metadata = extractMetadata(from: jpegData)
        }
    }

    func extractMetadata(from imageData: Data) -> String? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return "Failed to create image source"
        }
        
        guard let metadataDict = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any] else {
            return "No metadata found"
        }
        
        var extractedInfo: [String] = []
        
        // Function to recursively extract all metadata from dictionaries
        func extractDictionary(_ dict: [String: Any], prefix: String = "") {
            for (key, value) in dict.sorted(by: { $0.key < $1.key }) {
                let displayKey = prefix.isEmpty ? key : "\(prefix).\(key)"
                
                if let nestedDict = value as? [String: Any] {
                    // Add the dictionary name as a header
                    extractedInfo.append("\n\(displayKey):")
                    extractDictionary(nestedDict, prefix: displayKey)
                } else {
                    // Format the value based on its type
                    let formattedValue: String
                    if let array = value as? [Any] {
                        formattedValue = "\(array)"
                    } else {
                        formattedValue = "\(value)"
                    }
                    extractedInfo.append("  \(key): \(formattedValue)")
                }
            }
        }
        
        // Extract common metadata dictionaries with better formatting
        if let exifData = metadataDict[kCGImagePropertyExifDictionary as String] as? [String: Any] {
            extractedInfo.append("\nEXIF Data:")
            
            // Extract common EXIF properties with nice formatting
            let commonExifKeys: [(String, String)] = [
                (kCGImagePropertyExifExposureTime as String, "Exposure Time"),
                (kCGImagePropertyExifFNumber as String, "F Number"),
                (kCGImagePropertyExifISOSpeedRatings as String, "ISO"),
                (kCGImagePropertyExifFocalLength as String, "Focal Length"),
                (kCGImagePropertyExifLensMake as String, "Lens Make"),
                (kCGImagePropertyExifLensModel as String, "Lens Model"),
                (kCGImagePropertyExifDateTimeOriginal as String, "Date Taken")
            ]
            
            for (key, label) in commonExifKeys {
                if let value = exifData[key] {
                    extractedInfo.append("  \(label): \(value)")
                }
            }
            
            // Add any remaining EXIF data
            for (key, value) in exifData {
                if !commonExifKeys.map({ $0.0 }).contains(key) {
                    extractedInfo.append("  \(key): \(value)")
                }
            }
        }
        
        if let tiffData = metadataDict[kCGImagePropertyTIFFDictionary as String] as? [String: Any] {
            extractedInfo.append("\nCamera Information:")
            
            // Format common TIFF properties
            if let make = tiffData[kCGImagePropertyTIFFMake as String] as? String {
                extractedInfo.append("  Make: \(make)")
            }
            if let model = tiffData[kCGImagePropertyTIFFModel as String] as? String {
                extractedInfo.append("  Model: \(model)")
            }
            if let software = tiffData[kCGImagePropertyTIFFSoftware as String] as? String {
                extractedInfo.append("  Software: \(software)")
            }
            
            // Add any other TIFF data
            for (key, value) in tiffData {
                if ![kCGImagePropertyTIFFMake as String,
                     kCGImagePropertyTIFFModel as String,
                     kCGImagePropertyTIFFSoftware as String].contains(key) {
                    extractedInfo.append("  \(key): \(value)")
                }
            }
        }
        
        if let gpsData = metadataDict[kCGImagePropertyGPSDictionary as String] as? [String: Any] {
            extractedInfo.append("\nLocation Data:")
            
            // Format GPS coordinates properly when available
            if let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
               let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? Double {
                let direction = latitudeRef == "N" ? "North" : "South"
                extractedInfo.append("  Latitude: \(latitude)° \(direction)")
            }
            
            if let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String,
               let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? Double {
                let direction = longitudeRef == "E" ? "East" : "West"
                extractedInfo.append("  Longitude: \(longitude)° \(direction)")
            }
            
            if let altitude = gpsData[kCGImagePropertyGPSAltitude as String] as? Double {
                extractedInfo.append("  Altitude: \(altitude) meters")
            }
            
            // Add any other GPS data
            for (key, value) in gpsData {
                if ![kCGImagePropertyGPSLatitude as String,
                     kCGImagePropertyGPSLatitudeRef as String,
                     kCGImagePropertyGPSLongitude as String,
                     kCGImagePropertyGPSLongitudeRef as String,
                     kCGImagePropertyGPSAltitude as String].contains(key) {
                    extractedInfo.append("  \(key): \(value)")
                }
            }
        }
        
        // Image properties section
        extractedInfo.append("\nImage Properties:")
        if let width = metadataDict[kCGImagePropertyPixelWidth as String] as? Int,
           let height = metadataDict[kCGImagePropertyPixelHeight as String] as? Int {
            extractedInfo.append("  Dimensions: \(width) × \(height) pixels")
        }
        
        if let dpiWidth = metadataDict[kCGImagePropertyDPIWidth as String] as? Double,
           let dpiHeight = metadataDict[kCGImagePropertyDPIHeight as String] as? Double {
            extractedInfo.append("  Resolution: \(Int(dpiWidth)) × \(Int(dpiHeight)) DPI")
        }
        
        if let colorModel = metadataDict[kCGImagePropertyColorModel as String] as? String {
            extractedInfo.append("  Color Model: \(colorModel)")
        }
        
        if let depth = metadataDict[kCGImagePropertyDepth as String] as? Int {
            extractedInfo.append("  Bit Depth: \(depth)-bit")
        }
        
        // Add any other top-level metadata
        let commonKeys = [
            kCGImagePropertyPixelWidth as String,
            kCGImagePropertyPixelHeight as String,
            kCGImagePropertyDPIWidth as String,
            kCGImagePropertyDPIHeight as String,
            kCGImagePropertyColorModel as String,
            kCGImagePropertyDepth as String,
            kCGImagePropertyExifDictionary as String,
            kCGImagePropertyTIFFDictionary as String,
            kCGImagePropertyGPSDictionary as String
        ]
        
        for (key, value) in metadataDict {
            if !commonKeys.contains(key) {
                // Check if it's another dictionary that should be expanded
                if let dict = value as? [String: Any] {
                    extractedInfo.append("\n\(key):")
                    extractDictionary(dict, prefix: key)
                } else {
                    extractedInfo.append("  \(key): \(value)")
                }
            }
        }
        
        return extractedInfo.isEmpty ? "No metadata found." : extractedInfo.joined(separator: "\n")
    }

    func calculateChromaticity(from image: UIImage) -> (chromaticity: (mean: (CGFloat, CGFloat), stdDev: (CGFloat, CGFloat)), totalXYZ: (x: CGFloat, y: CGFloat, z: CGFloat), avgXYZ: (x: CGFloat, y: CGFloat, z: CGFloat))? {
        guard let cgImage = image.cgImage else { return nil }

        let width = cgImage.width
        let height = cgImage.height
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        let pixelCount = width * height

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

        var totalX: CGFloat = 0
        var totalY: CGFloat = 0
        var totalZ: CGFloat = 0
        var chromaticityValues: [(CGFloat, CGFloat)] = []
        var validPixelCount: Int = 0

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

            totalX += Xval
            totalY += Yval
            totalZ += Zval
            
            let sum = Xval + Yval + Zval
            
            if sum > 0 {
                chromaticityValues.append((Xval / sum, Yval / sum))
                validPixelCount += 1
            }
        }
        
        // Calculate average XYZ values - using valid pixel count to avoid division by zero
        let pixelsToUse = validPixelCount > 0 ? CGFloat(validPixelCount) : CGFloat(pixelCount)
        let avgX = totalX / pixelsToUse
        let avgY = totalY / pixelsToUse
        let avgZ = totalZ / pixelsToUse
        
        // Average XYZ values
        let avgXYZ = (x: avgX, y: avgY, z: avgZ)
        
        // Total XYZ values
        let totalXYZ = (x: totalX, y: totalY, z: totalZ)
        
        // Calculate mean chromaticity values
        let meanX = chromaticityValues.map { $0.0 }.reduce(0, +) / CGFloat(chromaticityValues.count)
        let meanY = chromaticityValues.map { $0.1 }.reduce(0, +) / CGFloat(chromaticityValues.count)

        // Calculate standard deviation for chromaticity
        let stdDevX = sqrt(chromaticityValues.map { pow($0.0 - meanX, 2) }.reduce(0, +) / CGFloat(chromaticityValues.count))
        let stdDevY = sqrt(chromaticityValues.map { pow($0.1 - meanY, 2) }.reduce(0, +) / CGFloat(chromaticityValues.count))

        return (chromaticity: (mean: (meanX, meanY), stdDev: (stdDevX, stdDevY)),
                totalXYZ: totalXYZ,
                avgXYZ: avgXYZ)
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
