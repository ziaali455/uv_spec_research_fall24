//
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

import Foundation
import SwiftUI
import UIKit
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraViewModel = CameraViewModel()
    @State private var snapshotHueMatrix: [[CGFloat]]? = nil

    var body: some View {
        NavigationView {
            VStack {
                if let liveHueMatrix = cameraViewModel.liveHueMatrix {
                    GridView(hueValues: liveHueMatrix)
                        .frame(width: 250, height: 250)
                } else {
                    Text("No live feed available")
                        .foregroundColor(.gray)
                }

                Button(action: {
                    snapshotHueMatrix = cameraViewModel.liveHueMatrix
                }) {
                    Text("Take Snapshot")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding()

                if let snapshot = snapshotHueMatrix {
                    Text("Snapshot Hue Matrix")
                        .font(.headline)
                    GridView(hueValues: snapshot)
                        .frame(width: 250, height: 250)
                }
            }
            .navigationTitle("Live Hue Matrix")
            .onAppear {
                cameraViewModel.startSession()
            }
            .onDisappear {
                cameraViewModel.stopSession()
            }
        }
    }
}

struct GridView: View {
    let hueValues: [[CGFloat]]

    var body: some View {
        VStack(spacing: 1) {
            ForEach(0..<hueValues.count, id: \ .self) { row in
                HStack(spacing: 1) {
                    ForEach(0..<hueValues[row].count, id: \ .self) { col in
                        ZStack {
                            Rectangle()
                                .fill(Color(hue: hueValues[row][col], saturation: 1.0, brightness: 1.0))
                            Text(String(format: "%.2f", hueValues[row][col]))
                                .font(.caption2)
                                .foregroundColor(.white)
                                .shadow(radius: 1)
                        }
                    }
                }
            }
        }
    }
}

final class CameraViewModel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    @Published var liveHueMatrix: [[CGFloat]]? = nil
    let session = AVCaptureSession()
    private let output = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "camera.session.queue") // Background queue for session management

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }

            do {
                self.session.beginConfiguration()

                let input = try AVCaptureDeviceInput(device: camera)
                if self.session.canAddInput(input) {
                    self.session.addInput(input)
                }

                if self.session.canAddOutput(self.output) {
                    self.session.addOutput(self.output)
                    self.output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera.frame.processing.queue"))
                }

                self.session.commitConfiguration()
                self.session.startRunning() // Start running the session on the background queue
            } catch {
                print("Failed to configure session: \(error)")
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)!

        let gridSize = 5 // Adjust the grid size as needed
        let rowStride = height / gridSize
        let colStride = width / gridSize

        var hueMatrix: [[CGFloat]] = Array(repeating: Array(repeating: 0.0, count: gridSize), count: gridSize)

        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let pixelOffset = ((row * rowStride) * bytesPerRow) + (col * colStride * 4)
                let r = CGFloat(baseAddress.assumingMemoryBound(to: UInt8.self)[pixelOffset + 1]) / 255.0
                let g = CGFloat(baseAddress.assumingMemoryBound(to: UInt8.self)[pixelOffset + 2]) / 255.0
                let b = CGFloat(baseAddress.assumingMemoryBound(to: UInt8.self)[pixelOffset + 3]) / 255.0

                // Calculate Hue using UIColor
                hueMatrix[row][col] = extractHue(r: r, g: g, b: b)
            }
        }

        DispatchQueue.main.async {
            self.liveHueMatrix = hueMatrix
        }

        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }

    private func extractHue(r: CGFloat, g: CGFloat, b: CGFloat) -> CGFloat {
        var hue: CGFloat = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        UIColor(red: r, green: g, blue: b, alpha: 1.0).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)
        return hue
    }
}





#Preview {
    ContentView()
}
