import SwiftUI
import UIKit
import UniformTypeIdentifiers
struct CameraPicker:UIViewControllerRepresentable {
    let onSelected:(URL)->Void
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator()->Coordinator {Coordinator(self)}
    func makeUIViewController(context:Context)->UIImagePickerController {
        let picker=UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes=[UTType.movie.identifier]
        picker.videoMaximumDuration=120
        picker.videoQuality = .typeMedium
        picker.delegate=context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController:UIImagePickerController,context:Context){}
    final class Coordinator:NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
        let parent:CameraPicker
        init(_ parent:CameraPicker){self.parent=parent}
        func imagePickerController(_ picker:UIImagePickerController,didFinishPickingMediaWithInfo info:[UIImagePickerController.InfoKey:Any]) {
            if let raw=info[.mediaURL] as? URL {
                let dest=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
                do {try FileManager.default.copyItem(at:raw,to:dest);parent.onSelected(dest)}catch{ /* User can select from library instead. */ }
            }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker:UIImagePickerController){parent.dismiss()}
    }
}
