import Foundation

actor ImageMigrationService {
    private let sheetsService = GoogleSheetsService()

    func migrateImages(configuration: SourceConfiguration) async throws -> ImageMigrationManifest {
        let menuData = try await sheetsService.loadMenuData(using: configuration)
        let sourceURLs = Array(Set(menuData.items.map(\.imageURL).filter { !$0.isEmpty })).sorted()
        guard !sourceURLs.isEmpty else {
            throw NSError(domain: "ImageMigrationService", code: 1, userInfo: [NSLocalizedDescriptionKey: "No item images found"])
        }

        let client = S3Client(configuration: configuration)
        var entries: [ImageMigrationManifest.Entry] = []

        for source in sourceURLs {
            guard let sourceURL = URL(string: source) else { continue }
            let (data, response) = try await URLSession.shared.data(from: sourceURL)
            guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                throw NSError(domain: "ImageMigrationService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to download \(source)"])
            }

            let key = buildImageKey(from: sourceURL)
            let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type") ?? "application/octet-stream"
            let targetURL = try await client.upload(data: data, key: key, contentType: contentType, cacheControl: "public, max-age=31536000, immutable")
            entries.append(.init(sourceURL: source, targetURL: targetURL.absoluteString, key: key, status: "uploaded"))
        }

        let manifest = ImageMigrationManifest(
            oldPrefix: "https://storage.yandexcloud.net/quickrestobase",
            newPrefix: "\(configuration.s3Endpoint)/\(configuration.bucket)/img",
            migratedCount: entries.count,
            items: entries
        )

        let manifestURL = AppPaths.distDirectory.appendingPathComponent("image-migration.json")
        let data = try JSONEncoder.prettyPrinted.encode(manifest)
        try data.write(to: manifestURL, options: .atomic)

        return manifest
    }

    private func buildImageKey(from sourceURL: URL) -> String {
        let components = sourceURL.pathComponents.filter { $0 != "/" }
        if components.count > 1 {
            return "img/" + components.dropFirst().joined(separator: "/")
        }
        return "img/" + sourceURL.lastPathComponent
    }
}
