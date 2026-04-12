import Foundation

actor PublishService {
    func publishArtifacts(configuration: SourceConfiguration) async throws -> [GeneratedArtifact] {
        let client = S3Client(configuration: configuration)
        let fileManager = FileManager.default
        let distURL = AppPaths.distDirectory
        let fileURLs = try fileManager.contentsOfDirectory(at: distURL, includingPropertiesForKeys: [.contentModificationDateKey], options: [.skipsHiddenFiles])
            .filter { $0.hasDirectoryPath == false }

        guard !fileURLs.isEmpty else {
            throw NSError(domain: "PublishService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No files found in dist. Build first."])
        }

        var uploaded: [GeneratedArtifact] = []

        for fileURL in fileURLs {
            let data = try Data(contentsOf: fileURL)
            let fileName = fileURL.lastPathComponent
            let key = objectKey(fileName: fileName, prefix: configuration.prefix)
            let contentType = contentType(for: fileName)
            let cacheControl = fileName.hasSuffix(".html") ? "public, max-age=60" : "public, max-age=31536000, immutable"
            _ = try await client.upload(data: data, key: key, contentType: contentType, cacheControl: cacheControl)
            let values = try fileURL.resourceValues(forKeys: [.contentModificationDateKey])
            uploaded.append(GeneratedArtifact(name: fileName, path: client.publicURL(for: key).absoluteString, updatedAt: values.contentModificationDate ?? Date()))
        }

        return uploaded
    }

    private func objectKey(fileName: String, prefix: String) -> String {
        let cleaned = prefix.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        return cleaned.isEmpty ? fileName : "\(cleaned)/\(fileName)"
    }

    private func contentType(for fileName: String) -> String {
        if fileName.hasSuffix(".html") { return "text/html; charset=utf-8" }
        if fileName.hasSuffix(".json") { return "application/json; charset=utf-8" }
        if fileName.hasSuffix(".yml") || fileName.hasSuffix(".xml") { return "application/xml; charset=utf-8" }
        if fileName.hasSuffix(".png") { return "image/png" }
        if fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg") { return "image/jpeg" }
        if fileName.hasSuffix(".webp") { return "image/webp" }
        return "application/octet-stream"
    }
}
