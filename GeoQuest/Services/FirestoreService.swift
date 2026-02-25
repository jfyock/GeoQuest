import FirebaseFirestore

final class FirestoreService {
    let db = Firestore.firestore()

    func getDocument<T: Decodable>(collection: String, documentId: String) async throws -> T? {
        let snapshot = try await db.collection(collection).document(documentId).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: T.self)
    }

    func setDocument<T: Encodable>(collection: String, documentId: String, data: T) async throws {
        try db.collection(collection).document(documentId).setData(from: data)
    }

    func addDocument<T: Encodable>(collection: String, data: T) async throws -> String {
        let ref = try db.collection(collection).addDocument(from: data)
        return ref.documentID
    }

    func updateFields(collection: String, documentId: String, fields: [String: Any]) async throws {
        try await db.collection(collection).document(documentId).updateData(fields)
    }

    func deleteDocument(collection: String, documentId: String) async throws {
        try await db.collection(collection).document(documentId).delete()
    }

    func query<T: Decodable>(
        collection: String,
        field: String,
        isEqualTo value: Any,
        orderBy: String? = nil,
        descending: Bool = false,
        limit: Int? = nil
    ) async throws -> [T] {
        var ref: Query = db.collection(collection).whereField(field, isEqualTo: value)
        if let orderBy { ref = ref.order(by: orderBy, descending: descending) }
        if let limit { ref = ref.limit(to: limit) }
        let snapshot = try await ref.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    func queryOrdered<T: Decodable>(
        collection: String,
        orderBy: String,
        descending: Bool = true,
        limit: Int? = nil
    ) async throws -> [T] {
        var ref: Query = db.collection(collection).order(by: orderBy, descending: descending)
        if let limit { ref = ref.limit(to: limit) }
        let snapshot = try await ref.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    func queryWithPrefix<T: Decodable>(
        collection: String,
        field: String,
        prefix: String
    ) async throws -> [T] {
        let end = prefix + "\u{f8ff}"
        let snapshot = try await db.collection(collection)
            .whereField(field, isGreaterThanOrEqualTo: prefix)
            .whereField(field, isLessThan: end)
            .getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }

    // Subcollection helpers
    func getSubDocument<T: Decodable>(
        parentCollection: String,
        parentId: String,
        subCollection: String,
        documentId: String
    ) async throws -> T? {
        let snapshot = try await db.collection(parentCollection)
            .document(parentId)
            .collection(subCollection)
            .document(documentId)
            .getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: T.self)
    }

    func setSubDocument<T: Encodable>(
        parentCollection: String,
        parentId: String,
        subCollection: String,
        documentId: String,
        data: T
    ) async throws {
        try db.collection(parentCollection)
            .document(parentId)
            .collection(subCollection)
            .document(documentId)
            .setData(from: data)
    }

    func querySubCollection<T: Decodable>(
        parentCollection: String,
        parentId: String,
        subCollection: String,
        orderBy: String? = nil,
        descending: Bool = false,
        limit: Int? = nil
    ) async throws -> [T] {
        var ref: Query = db.collection(parentCollection)
            .document(parentId)
            .collection(subCollection)
        if let orderBy { ref = ref.order(by: orderBy, descending: descending) }
        if let limit { ref = ref.limit(to: limit) }
        let snapshot = try await ref.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: T.self) }
    }
}
