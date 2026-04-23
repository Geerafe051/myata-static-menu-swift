import Foundation

struct MenuBuildResult {
    var menuData: MenuData
    var artifacts: [GeneratedArtifact]
}

actor MenuBuildService {
    private let sheetsService = GoogleSheetsService()

    func build(using configuration: SourceConfiguration) async throws -> MenuBuildResult {
        try FileManager.default.createDirectory(at: AppPaths.distDirectory, withIntermediateDirectories: true)

        let menuData = try await sheetsService.loadMenuData(using: configuration)

        let htmlURL = AppPaths.distDirectory.appendingPathComponent("index.html")
        let jsonURL = AppPaths.distDirectory.appendingPathComponent("menu.json")
        let ymlURL = AppPaths.distDirectory.appendingPathComponent("yandex-menu.yml")
        let backgroundURL = AppPaths.distDirectory.appendingPathComponent("menu-background.png")

        try HTMLRenderer.render(menuData: menuData).write(to: htmlURL, atomically: true, encoding: .utf8)
        let jsonData = try JSONEncoder.prettyPrinted.encode(menuData)
        try jsonData.write(to: jsonURL, options: .atomic)
        try YandexYMLRenderer.render(menuData: menuData).write(to: ymlURL, atomically: true, encoding: .utf8)
        try copyBackgroundImage(to: backgroundURL)

        let artifacts = try [htmlURL, jsonURL, ymlURL, backgroundURL].map { url in
            let values = try url.resourceValues(forKeys: [.contentModificationDateKey])
            return GeneratedArtifact(
                name: url.lastPathComponent,
                path: url.path(),
                updatedAt: values.contentModificationDate ?? Date()
            )
        }

        return MenuBuildResult(menuData: menuData, artifacts: artifacts)
    }

    private func copyBackgroundImage(to destinationURL: URL) throws {
        let sourceURL = try resolveBackgroundImageURL()
        let data = try Data(contentsOf: sourceURL)
        try data.write(to: destinationURL, options: .atomic)
    }

    private func resolveBackgroundImageURL() throws -> URL {
        if let bundledURL = Bundle.main.url(forResource: "menu-background", withExtension: "png") {
            return bundledURL
        }

        let currentFileURL = URL(fileURLWithPath: #filePath)
        let repositoryRoot = currentFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let fallbackURL = repositoryRoot.appendingPathComponent("Resources/menu-background.png")

        if FileManager.default.fileExists(atPath: fallbackURL.path()) {
            return fallbackURL
        }

        throw NSError(domain: "MenuBuildService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Menu background image is missing"])
    }
}
