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

        try HTMLRenderer.render(menuData: menuData).write(to: htmlURL, atomically: true, encoding: .utf8)
        let jsonData = try JSONEncoder.prettyPrinted.encode(menuData)
        try jsonData.write(to: jsonURL, options: .atomic)
        try YandexYMLRenderer.render(menuData: menuData).write(to: ymlURL, atomically: true, encoding: .utf8)

        let artifacts = try [htmlURL, jsonURL, ymlURL].map { url in
            let values = try url.resourceValues(forKeys: [.contentModificationDateKey])
            return GeneratedArtifact(
                name: url.lastPathComponent,
                path: url.path(),
                updatedAt: values.contentModificationDate ?? Date()
            )
        }

        return MenuBuildResult(menuData: menuData, artifacts: artifacts)
    }
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}
