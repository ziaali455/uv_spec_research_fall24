//  ContentView.swift
//  uvsn_live
//
//  Created by Ali Zia on 12/19/24.
//

import SwiftUI
import AVFoundation

import Foundation
import SwiftUI
import UIKit
import AVFoundation

//struct ContentView: View {
//    @StateObject private var cameraViewModel = CameraViewModel()
//    @State private var snapshotHueMatrix: [[CGFloat]]? = nil
//    @State private var snapshotChromaticityMatrix: [[(CGFloat, CGFloat)]]? = nil
//
//    var body: some View {
//        NavigationView {
//            VStack {
//                if let liveHueMatrix = cameraViewModel.liveHueMatrix {
//                    Text("Live Hue Matrix")
//                        .font(.headline)
//                    GridView(hueValues: liveHueMatrix)
//                        .frame(width: 250, height: 250)
//                } else {
//                    Text("No live feed available")
//                        .foregroundColor(.gray)
//                }
//
//                if let liveChromaticityMatrix = cameraViewModel.liveChromaticityMatrix {
//                    Text("Live Chromaticity Matrix")
//                        .font(.headline)
//                    ChromaticityGridView(chromaticityValues: liveChromaticityMatrix)
//                        .frame(width: 250, height: 250)
//                }
//
//                Button(action: {
//                    snapshotHueMatrix = cameraViewModel.liveHueMatrix
//                    snapshotChromaticityMatrix = cameraViewModel.liveChromaticityMatrix
//                }) {
//                    Text("Take Snapshot")
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(8)
//                }
//                .padding()
//
//                if let snapshot = snapshotHueMatrix {
//                    Text("Snapshot Hue Matrix")
//                        .font(.headline)
//                    GridView(hueValues: snapshot)
//                        .frame(width: 250, height: 250)
//                }
//
//                if let snapshot = snapshotChromaticityMatrix {
//                    Text("Snapshot Chromaticity Matrix")
//                        .font(.headline)
//                    ChromaticityGridView(chromaticityValues: snapshot)
//                        .frame(width: 250, height: 250)
//                }
//            }
//            .navigationTitle("Live Hue Matrix")
//            .onAppear {
//                cameraViewModel.startSession()
//            }
//            .onDisappear {
//                cameraViewModel.stopSession()
//            }
//        }
//    }
//}
//
//struct GridView: View {
//    let hueValues: [[CGFloat]]
//
//    var body: some View {
//        VStack(spacing: 1) {
//            ForEach(0..<hueValues.count, id: \ .self) { row in
//                HStack(spacing: 1) {
//                    ForEach(0..<hueValues[row].count, id: \ .self) { col in
//                        ZStack {
//                            Rectangle()
//                                .fill(Color(hue: hueValues[row][col], saturation: 1.0, brightness: 1.0))
//                            Text(String(format: "%.2f", hueValues[row][col]))
//                                .font(.caption2)
//                                .foregroundColor(.white)
//                                .shadow(radius: 1)
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//struct ChromaticityGridView: View {
//    let chromaticityValues: [[(CGFloat, CGFloat)]]
//
//    var body: some View {
//        VStack(spacing: 1) {
//            ForEach(0..<chromaticityValues.count, id: \ .self) { row in
//                HStack(spacing: 1) {
//                    ForEach(0..<chromaticityValues[row].count, id: \ .self) { col in
//                        ZStack {
//                            Rectangle()
//                                .fill(Color.gray)
//                            Text(String(format: "r: %.2f\ng: %.2f", chromaticityValues[row][col].0, chromaticityValues[row][col].1))
//                                .font(.caption2)
//                                .foregroundColor(.white)
//                                .shadow(radius: 1)
//                                .multilineTextAlignment(.center)
//                        }
//                    }
//                }
//            }
//        }
//    }
//}
//
//final class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
//    @Published var liveHueMatrix: [[CGFloat]]? = nil
//    @Published var liveChromaticityMatrix: [[(CGFloat, CGFloat)]]? = nil
//    private var lastUpdateTime: Date = Date.distantPast
//    private let throttleInterval: TimeInterval = 1.0 // Capture hue matrix every 1 second
//    let session = AVCaptureSession()
//    private let output = AVCaptureVideoDataOutput()
//    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // Background queue for session management
//
//    func startSession() {
//        sessionQueue.async { [weak self] in
//            guard let self = self,
//                  let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
//
//            do {
//                self.session.beginConfiguration()
//
//                let input = try AVCaptureDeviceInput(device: camera)
//                if self.session.canAddInput(input) {
//                    self.session.addInput(input)
//                }
//
//                if self.session.canAddOutput(self.output) {
//                    self.session.addOutput(self.output)
//                    self.output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
//                }
//
//                self.session.commitConfiguration()
//                self.session.startRunning() // Start running the session on the background queue
//            } catch {
//                print("Failed to configure session: \(error)")
//            }
//        }
//    }
//
//    func stopSession() {
//        sessionQueue.async { [weak self] in
//            self?.session.stopRunning()
//        }
//    }
//
//    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
//        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        let currentTime = Date()
//        guard currentTime.timeIntervalSince(lastUpdateTime) >= throttleInterval else { return }
//        lastUpdateTime = currentTime
//
//        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
//
//        let width = CVPixelBufferGetWidth(pixelBuffer)
//        let height = CVPixelBufferGetHeight(pixelBuffer)
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!
//
//        let gridSize = 5 // Adjust the grid size as needed
//        let rowStride = height / gridSize
//        let colStride = width / gridSize
//
//        var hueMatrix: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize)
//        var chromaticityMatrix: [[(CGFloat, CGFloat)]] = Array(repeating: Array(repeating: (0.0, 0.0), count: gridSize), count: gridSize)
//
//        for row in 0..<gridSize {
//            for col in 0..<gridSize {
//                let pixelOffset = ((row * rowStride) * bytesPerRow) + (col * colStride * 2)
//                let r = CGFloat(baseAddress.assumingMemoryBound(to: UInt8.self)[pixelOffset + 1])
//                let g = CGFloat(baseAddress.assumingMemoryBound(to: UInt8.self)[pixelOffset + 2])
//                let b = CGFloat(baseAddress.assumingMemoryBound(to: UInt8.self)[pixelOffset + 3])
//
//                let sum = r + g + b
//                let normalizedR = r / sum
//                let normalizedG = g / sum
//
//                // Calculate Hue using UIColor
//                hueMatrix[row][col] = extractHue(r: r, g: g, b: b)
//                chromaticityMatrix[row][col] = (normalizedR, normalizedG)
//            }
//        }
//
//        DispatchQueue.main.async {
//            self.liveHueMatrix = hueMatrix
//            self.liveChromaticityMatrix = chromaticityMatrix
//        }
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
//    }
//
//    private func extractHue(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
//        var hue: CGFloat = 0.0
//        var saturation: CGFloat = 0.0
//        var brightness: CGFloat = 0.0
//        UIColor(red: r, green: g, blue: b, alpha: 1.0).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
//        return hue
//    }
//    
//    func calculateAverageChromaticity(from chromaticityMatrix: [[(CGFloat, CGFloat)]]) -> (CGFloat, CGFloat) {
//        var totalR: CGFloat = 0.0
//        var totalG: CGFloat = 0.0
//        var count: Int = 0
//
//        for row in chromaticityMatrix {
//            for chromaticity in row {
//                totalR += chromaticity.0
//                totalG += chromaticity.1
//                count += 1
//            }
//        }
//
//        guard count > 0 else {
//            return (0.0, 0.0) // Handle the edge case of an empty matrix
//        }
//
//        let averageR = totalR / CGFloat(count)
//        let averageG = totalG / CGFloat(count)
//
//        return (averageR, averageG)
//    }
//
//}
import SwiftUI
import UIKit

struct ContentView: View {
    @State private var averageChromaticity: (CGFloat, CGFloat)? = nil
    @State private var averageXYChromaticity: (CGFloat, CGFloat)? = nil
    @State private var isPickerPresented = false

    var body: some View {
        VStack(spacing: 20) {
            if let chromaticity = averageChromaticity, let xyChromaticity = averageXYChromaticity {
                Text("Average Chromaticity")
                    .font(.headline)
                Text(String(format: "r: %.2f, g: %.2f", chromaticity.0, chromaticity.1))
                    .font(.body)
                    .padding()

                Text("Average x, y Chromaticity")
                    .font(.headline)
                Text(String(format: "x: %.2f, y: %.2f", xyChromaticity.0, xyChromaticity.1))
                    .font(.body)
                    .padding()
            } else {
                Text("No image selected")
                    .foregroundColor(.gray)
            }

            Button(action: {
                isPickerPresented = true
            }) {
                Text("Upload Image")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            ImagePicker(onImagePicked: { image in
                let chromaticity = calculateAverageChromaticity(from: image)
                averageChromaticity = chromaticity.rgbChromaticity
                averageXYChromaticity = chromaticity.xyChromaticity
            })
        }
        .padding()
    }

    func calculateAverageChromaticity(from image: UIImage) -> (rgbChromaticity: (CGFloat, CGFloat), xyChromaticity: (CGFloat, CGFloat)) {
        guard let cgImage = image.cgImage else { return ((0.0, 0.0), (0.0, 0.0)) }

        let width = cgImage.width
        let height = cgImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let totalBytes = height * bytesPerRow

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else { return ((0.0, 0.0), (0.0, 0.0)) }
        var pixelData = [UInt8](repeating: 0, count: totalBytes)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8, //confused, should this be 3?
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return ((0.0, 0.0), (0.0, 0.0))
        }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalR: CGFloat = 0.0
        var totalG: CGFloat = 0.0
        var totalB: CGFloat = 0.0
        var count: Int = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0

                let sum = r + g + b
                if sum > 0 {
                    let normalizedR = r / sum
                    let normalizedG = g / sum
                    let normalizedB = b / sum
                    totalR += normalizedR
                    totalG += normalizedG
                    totalB += normalizedB
                    count += 1
                }
            }
        }

        guard count > 0 else { return ((0.0, 0.0), (0.0, 0.0)) }

        let averageR = totalR / CGFloat(count)
        let averageG = totalG / CGFloat(count)
        let averageB = totalB / CGFloat(count)

        //potentially extract magnitude of G
        
        
        // Calculate x, y chromaticity
        let x = averageR / (averageR + averageG + averageB)
        let y = averageG / (averageR + averageG + averageB)

        return ((averageR, averageG), (x, y))
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    var onImagePicked: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var onImagePicked: (UIImage) -> Void

        init(onImagePicked: @escaping (UIImage) -> Void) {
            self.onImagePicked = onImagePicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            }
            picker.dismiss(animated: true)
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
