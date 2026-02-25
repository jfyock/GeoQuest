import FirebaseStorage
import Foundation

final class StorageService {
    private let storage = Storage.storage()

    func uploadImage(data: Data, path: String) async throws -> URL {
        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        return try await ref.downloadURL()
    }

    func deleteImage(path: String) async throws {
        try await storage.reference().child(path).delete()
    }

    func downloadURL(path: String) async throws -> URL {
        try await storage.reference().child(path).downloadURL()
    }
}
