//
//  CaptureView.swift
//  uvsn
//
//  Created by Ali Zia on 11/7/24.
//

import Foundation
import SwiftUI
import UIKit
import AVFoundation

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
            CustomCameraView(image: $inputImage, isShowingCamera: $isShowingCamera)
        }
    }

    private func processImageForHues(_ image: UIImage) -> [[CGFloat]] {
        // Resize the image to reduce the number of pixels to process
        let resizedImage = image // Adjust the target size as needed

        guard let cgImage = resizedImage.cgImage else {
            print("Error: Could not get CGImage")
            return []
        }

        let pixelData = cgImage.dataProvider?.data
        let data = CFDataGetBytePtr(pixelData)

        let width = cgImage.width
        let height = cgImage.height

        // Initialize an empty 2D array (matrix) for the hue values
        var hueMatrix: [[CGFloat]] = Array(repeating: Array(repeating: 0, count: width), count: height)

        // Loop through each pixel (RGBA format: R, G, B, A)
        for x in 0..<width {
            for y in 0..<height {
                let pixelInfo = ((width * y) + x) * 4  // Each pixel is represented by 4 values (R, G, B, A)

                // Safely unwrap pixel data to avoid crashes
                guard let r = data?[pixelInfo],
                      let g = data?[pixelInfo + 1],
                      let b = data?[pixelInfo + 2],
                      let a = data?[pixelInfo + 3] else {
                    print("Error: Pixel data is invalid")
                    continue
                }

                // Convert the RGBA values to CGFloat [0, 1] range
                let rValue = CGFloat(r) / 255.0
                let gValue = CGFloat(g) / 255.0
                let bValue = CGFloat(b) / 255.0
                let aValue = CGFloat(a) / 255.0

                // Use UIColor to extract Hue from RGBA
                var hue: CGFloat = 0
                var saturation: CGFloat = 0
                var brightness: CGFloat = 0

                // Create a UIColor from RGBA and extract the hue component
                UIColor(red: rValue, green: gValue, blue: bValue, alpha: aValue)
                    .getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil)

                // Handle black pixels or low saturation pixels (hue undefined)
                if rValue == 0 && gValue == 0 && bValue == 0 {
                    hue = 0
                } else if saturation < 0.1 {
                    hue = 0
                }

                // Store the hue value in the matrix
                hueMatrix[y][x] = hue
            }
        }

        return hueMatrix
    }
}

// MARK: - Custom Camera View
struct CustomCameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var isShowingCamera: Bool

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }

    class Coordinator: NSObject, CameraViewControllerDelegate {
        var parent: CustomCameraView

        init(_ parent: CustomCameraView) {
            self.parent = parent
        }

        func cameraViewControllerDidCapture(image: UIImage) {
            parent.image = image
            parent.isShowingCamera = false
        }

        func cameraViewControllerDidCancel() {
            parent.isShowingCamera = false
        }
    }
}

// MARK: - Camera View Controller
protocol CameraViewControllerDelegate: AnyObject {
    func cameraViewControllerDidCapture(image: UIImage)
    func cameraViewControllerDidCancel()
}

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate {
    weak var delegate: CameraViewControllerDelegate?
    private let captureSession = AVCaptureSession()
    private let photoOutput = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    private let shutterButton: UIButton = {
        let button = UIButton(type: .custom)
        button.backgroundColor = .white
        button.layer.cornerRadius = 35
        button.layer.borderColor = UIColor.gray.cgColor
        button.layer.borderWidth = 3
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCamera()
        setupUI()
    }

    private func setupCamera() {
        captureSession.beginConfiguration()

        // Configure input
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(input) else {
            print("Error: Unable to add camera input.")
            return
        }
        captureSession.addInput(input)

        // Configure output
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        }
        photoOutput.isHighResolutionCaptureEnabled = true

        if !photoOutput.availableRawPhotoPixelFormatTypes.isEmpty {
            print("RAW photo capture is supported.")
        } else {
            print("RAW photo capture is not supported on this device.")
        }

        captureSession.commitConfiguration()

        // Configure preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        // Start the session
        captureSession.startRunning()
    }

    private func setupUI() {
        // Add shutter button to the view
        view.addSubview(shutterButton)
        NSLayoutConstraint.activate([
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            shutterButton.widthAnchor.constraint(equalToConstant: 70),
            shutterButton.heightAnchor.constraint(equalToConstant: 70)
        ])

        // Add target for shutter button
        shutterButton.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
    }

    @objc private func shutterButtonTapped() {
        if let rawPixelFormat = photoOutput.availableRawPhotoPixelFormatTypes.first {
            let photoSettings = AVCapturePhotoSettings(rawPixelFormatType: rawPixelFormat)
            photoOutput.capturePhoto(with: photoSettings, delegate: self)
        } else {
            print("RAW photo format is unavailable.")
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard error == nil,
              let rawData = photo.fileDataRepresentation(),
              let image = UIImage(data: rawData) else {
            print("Error capturing photo: \(error?.localizedDescription ?? "Unknown error")")
            return
        }

        delegate?.cameraViewControllerDidCapture(image: image)
    }

    func cancel() {
        delegate?.cameraViewControllerDidCancel()
    }
}
