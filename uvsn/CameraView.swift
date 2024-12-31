import Foundation
import SwiftUI
import AVFoundation

enum CameraError: Error {
    case setupFailed
}

struct CameraView: View {
    @State private var captureSession = AVCaptureSession()
    @State private var photoOutput = AVCapturePhotoOutput()
    @State private var currentVideoInput: AVCaptureDeviceInput?
    @State private var capturedImage: UIImage?

    var body: some View {
        VStack {
            // Display captured image or camera preview
            if let capturedImage = capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
            } else {
                CameraPreview(session: captureSession)
                    .frame(width: 300, height: 300)
                    .background(Color.gray)
            }

            Button("Capture Photo") {
                capturePhoto()
            }
            .padding()
        }
        .onAppear {
            do {
                try setupSession()
                captureSession.startRunning()
            } catch {
                print("Error setting up camera session: \(error)")
            }
        }
    }

    // MARK: - Setup Camera Session
    private func setupSession() throws {
        captureSession.beginConfiguration()

        // Configure the session for photo capture.
        captureSession.sessionPreset = .photo
        
        // Get the default video device (camera)
        guard let defaultVideoDevice = AVCaptureDevice.default(for: .video) else {
            throw CameraError.setupFailed
        }
        
        // Connect the default video device.
        let videoInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
            currentVideoInput = videoInput
        } else {
            throw CameraError.setupFailed
        }
        
        // Connect and configure the capture output.
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
            
            // Enable ProRAW if supported
            if photoOutput.isAppleProRAWSupported {
                photoOutput.isAppleProRAWEnabled = true
            }
        } else {
            throw CameraError.setupFailed
        }

        captureSession.commitConfiguration()
    }

    // MARK: - Capture Photo
    private func capturePhoto() {
        // Ensure that the capture session is running
        guard captureSession.isRunning else { return }

        let settings = AVCapturePhotoSettings()
        photoOutput.isAppleProRAWEnabled = photoOutput.isAppleProRAWSupported

        photoOutput.capturePhoto(with: settings, delegate: PhotoCaptureDelegate { image in
            self.capturedImage = image
        })
    }
}

// MARK: - AVCapturePhotoCaptureDelegate (SwiftUI Bridge)
class PhotoCaptureDelegate: NSObject, AVCapturePhotoCaptureDelegate {
    private var completion: (UIImage) -> Void

    init(completion: @escaping (UIImage) -> Void) {
        self.completion = completion
    }

    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            return
        }

        // Process the raw photo or standard image
        if let rawPhotoData = photo.fileDataRepresentation() {
            if let image = UIImage(data: rawPhotoData) {
                completion(image)
            }
        }
    }
}

// MARK: - Camera Preview (UIViewRepresentable)
struct CameraPreview: UIViewRepresentable {
    var session: AVCaptureSession

    func makeUIView(context: Context) -> UIView {
        let previewView = UIView()
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = previewView.bounds
        previewLayer.videoGravity = .resizeAspectFill
        previewView.layer.addSublayer(previewLayer)
        return previewView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Update the preview layer when the view updates.
        if let layer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
            layer.frame = uiView.bounds
        }
    }
}
