//TODO: Raw conversion
import SwiftUI
struct ImagePicker: UIViewControllerRepresentable {
@Binding var image: UIImage?
@Binding var isShowingCamera: Bool

class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    var parent: ImagePicker

    init(parent: ImagePicker) {
        self.parent = parent
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let uiImage = info[.originalImage] as? UIImage {
            parent.image = uiImage
        }
        parent.isShowingCamera = false
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        parent.isShowingCamera = false
    }
}

func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
}

func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
}

func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
}
