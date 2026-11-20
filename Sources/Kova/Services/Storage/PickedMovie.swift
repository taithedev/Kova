import Foundation
import CoreTransferable
import UniformTypeIdentifiers
struct PickedMovie:Transferable {
    let url:URL
    static var transferRepresentation:some TransferRepresentation {
        FileRepresentation(contentType:.movie){SentTransferredFile($0.url)} importing:{received in
            let target=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension)
            try FileManager.default.copyItem(at:received.file,to:target)
            return PickedMovie(url:target)
        }
    }
}
