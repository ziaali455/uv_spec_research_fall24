
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import Accelerate
import UIKit
import ImageIO
import PhotosUI
/**

 RAW Image Detection:

    The CGImageSourceGetType function is used to check if the image is in a RAW format by looking for the raw substring in the UTType.

 RAW to PNG Conversion:

     If the image is RAW, it is converted to a CGImage and then to a UIImage.

     The UIImage is then converted to PNG data using pngData().

 Non-RAW Images:

     Non-RAW images are processed directly without conversion.

     Threading:

     The image processing and conversion are performed on a background thread to avoid blocking the UI.
 
 
 */
class MainViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var inputImage: UIImage?
    @Published var chromaticity: (x: CGFloat, y: CGFloat)?
    @Published var chromaticityStdDev: (x: CGFloat, y: CGFloat)?
    @Published var rgbValues: (r: Int, g: Int, b: Int)?
    @Published var metadata: String?
    @Published var xyzValues: (x: CGFloat, y: CGFloat, z: CGFloat)?
    @Published var avgXYZValues: (x: CGFloat, y: CGFloat, z: CGFloat)?
    @Published var selectedItem: PhotosPickerItem?
    @Published var isLoading = false
    @Published var isExporting = false

    // MARK: - Computed Properties
    var isExportEnabled: Bool {
        return inputImage != nil && (chromaticity != nil || rgbValues != nil || metadata != nil)
    }

    // MARK: - Image Processing
    func processImage(imageData: Data? = nil) {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            guard let image = self.inputImage else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            // Convert RAW image to PNG if necessary
            let processedImage: UIImage
            if let data = imageData, let source = CGImageSourceCreateWithData(data as CFData, nil) {
                let utType = CGImageSourceGetType(source) as String?
                let isRAWImage = utType?.contains("raw") ?? false

                if isRAWImage {
                    // Convert RAW image to PNG
                    if let pngData = self.convertRAWToPNG(imageData: data) {
                        processedImage = UIImage(data: pngData) ?? image
                    } else {
                        processedImage = image
                    }
                } else {
                    // Handle non-RAW images
                    let options: [CFString: Any] = [
                        kCGImageSourceShouldCache: false,
                        kCGImageSourceShouldAllowFloat: true
                    ]
                    if let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) {
                        processedImage = UIImage(cgImage: cgImage)
                    } else {
                        processedImage = image
                    }
                }
            } else {
                processedImage = image
            }

            // Perform chromaticity and RGB calculations
            let colorData = self.calculateChromaticity(from: processedImage)
            let extractedRGB = self.extractRGB(from: processedImage)
            
            // Extract metadata
            var extractedMetadata: String? = nil
            if let data = imageData {
                extractedMetadata = self.extractMetadata(from: data)
            } else if let jpegData = processedImage.jpegData(compressionQuality: 1.0) {
                extractedMetadata = self.extractMetadata(from: jpegData)
            }

            // Update UI on the main thread
            DispatchQueue.main.async {
                self.chromaticity = colorData?.chromaticity.mean
                self.chromaticityStdDev = colorData?.chromaticity.stdDev
                self.xyzValues = colorData?.totalXYZ
                self.avgXYZValues = colorData?.avgXYZ
                self.rgbValues = extractedRGB
                self.metadata = extractedMetadata
                self.isLoading = false
            }
        }
    }

    // MARK: - RAW to PNG Conversion
    private func convertRAWToPNG(imageData: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return nil
        }

        // Create a CGImage from the RAW data
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false,
            kCGImageSourceShouldAllowFloat: true
        ]
        guard let cgImage = CGImageSourceCreateImageAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }

        // Convert CGImage to PNG data
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage.pngData()
    }

    // MARK: - Helper Methods
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

    // MARK: - Export Data
    func exportData() {
        guard isExportEnabled else { return }

        let exportDict: [String: Any] = [
            "Chromaticity": chromaticity.map { ["x": $0.x, "y": $0.y] } ?? [:],
            "RGB": rgbValues.map { ["r": $0.r, "g": $0.g, "b": $0.b] } ?? [:],
            "Metadata": metadata ?? "No metadata available"
        ]

        if let jsonData = try? JSONSerialization.data(withJSONObject: exportDict, options: .prettyPrinted) {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("export.json")
            try? jsonData.write(to: tempURL)

            let activityView = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                scene.windows.first?.rootViewController?.present(activityView, animated: true, completion: nil)
            }
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
}
