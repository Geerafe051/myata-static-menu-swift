import Foundation

struct SourceConfiguration: Codable, Equatable {
    var spreadsheetURL: String = "https://docs.google.com/spreadsheets/d/1s4R3MAhKlQLbCyy-AFl9QISEviAcgik5fxkwPpD_lUc/edit?usp=sharing"
    var googleSheetID: String = "1s4R3MAhKlQLbCyy-AFl9QISEviAcgik5fxkwPpD_lUc"
    var settingsGID: String = "1486340064"
    var categoriesGID: String = "0"
    var itemsGID: String = "823879448"
    var s3Endpoint: String = "https://storage.yandexcloud.net"
    var s3Region: String = "ru-central1"
    var bucket: String = "hookah-menu-feed"
    var prefix: String = "menu"
    var accessKeyID: String = ""
    var secretAccessKey: String = ""
    var publicMenuURL: String = "https://storage.yandexcloud.net/hookah-menu-feed/menu/index.html"
    var yandexVendor: String = "Мята Ленинский"

    var resolvedGoogleSheetID: String {
        if let extracted = extractSheetID(from: spreadsheetURL), !extracted.isEmpty {
            return extracted
        }

        return googleSheetID
    }

    func csvURL(forSheetNamed sheetName: String) -> URL? {
        guard !resolvedGoogleSheetID.isEmpty, !sheetName.isEmpty else {
            return nil
        }

        let encodedSheetName = sheetName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? sheetName
        return URL(string: "https://docs.google.com/spreadsheets/d/\(resolvedGoogleSheetID)/gviz/tq?tqx=out:csv&sheet=\(encodedSheetName)")
    }

    func legacyCSVURL(for gid: String) -> URL? {
        guard !resolvedGoogleSheetID.isEmpty, !gid.isEmpty else {
            return nil
        }

        return URL(string: "https://docs.google.com/spreadsheets/d/\(resolvedGoogleSheetID)/export?format=csv&gid=\(gid)")
    }

    enum CodingKeys: String, CodingKey {
        case spreadsheetURL
        case googleSheetID
        case settingsGID
        case categoriesGID
        case itemsGID
        case s3Endpoint
        case s3Region
        case bucket
        case prefix
        case publicMenuURL
        case yandexVendor
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        googleSheetID = try container.decodeIfPresent(String.self, forKey: .googleSheetID) ?? "1s4R3MAhKlQLbCyy-AFl9QISEviAcgik5fxkwPpD_lUc"
        let storedSpreadsheetURL = try container.decodeIfPresent(String.self, forKey: .spreadsheetURL) ?? ""
        spreadsheetURL = storedSpreadsheetURL.isEmpty
            ? "https://docs.google.com/spreadsheets/d/\(googleSheetID)/edit?usp=sharing"
            : storedSpreadsheetURL
        settingsGID = try container.decodeIfPresent(String.self, forKey: .settingsGID) ?? "1486340064"
        categoriesGID = try container.decodeIfPresent(String.self, forKey: .categoriesGID) ?? "0"
        itemsGID = try container.decodeIfPresent(String.self, forKey: .itemsGID) ?? "823879448"
        s3Endpoint = try container.decodeIfPresent(String.self, forKey: .s3Endpoint) ?? "https://storage.yandexcloud.net"
        s3Region = try container.decodeIfPresent(String.self, forKey: .s3Region) ?? "ru-central1"
        bucket = try container.decodeIfPresent(String.self, forKey: .bucket) ?? "hookah-menu-feed"
        prefix = try container.decodeIfPresent(String.self, forKey: .prefix) ?? "menu"
        publicMenuURL = try container.decodeIfPresent(String.self, forKey: .publicMenuURL) ?? "https://storage.yandexcloud.net/hookah-menu-feed/menu/index.html"
        yandexVendor = try container.decodeIfPresent(String.self, forKey: .yandexVendor) ?? "Мята Ленинский"
        accessKeyID = ""
        secretAccessKey = ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(spreadsheetURL, forKey: .spreadsheetURL)
        try container.encode(resolvedGoogleSheetID, forKey: .googleSheetID)
        try container.encode(settingsGID, forKey: .settingsGID)
        try container.encode(categoriesGID, forKey: .categoriesGID)
        try container.encode(itemsGID, forKey: .itemsGID)
        try container.encode(s3Endpoint, forKey: .s3Endpoint)
        try container.encode(s3Region, forKey: .s3Region)
        try container.encode(bucket, forKey: .bucket)
        try container.encode(prefix, forKey: .prefix)
        try container.encode(publicMenuURL, forKey: .publicMenuURL)
        try container.encode(yandexVendor, forKey: .yandexVendor)
    }

    private func extractSheetID(from value: String) -> String? {
        guard !value.isEmpty else {
            return nil
        }

        if let range = value.range(of: #"/d/([a-zA-Z0-9-_]+)"#, options: .regularExpression) {
            let match = String(value[range])
            return String(match.dropFirst(3))
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

struct MenuSettings: Codable {
    var venueName: String
    var subtitle: String
    var description: String
    var logoURL: String
    var faviconURL: String
    var address: String
    var phone: String
    var instagram: String
    var menuURL: String
    var yandexVendor: String
}

struct MenuCategory: Codable, Identifiable {
    var id: String
    var name: String
    var sortOrder: Int
    var visible: Bool
}

struct MenuItem: Codable, Identifiable {
    var id: String
    var categoryID: String
    var name: String
    var price: Int
    var description: String
    var calories: String
    var proteins: String
    var fats: String
    var carbohydrates: String
    var portion: String
    var imageURL: String
    var available: Bool
    var availableOnMap: Bool
    var showNutritionFacts: Bool
    var sortOrder: Int
}

struct MenuSection: Codable, Identifiable {
    var id: String { category.id }
    var category: MenuCategory
    var items: [MenuItem]
}

struct MenuData: Codable {
    var settings: MenuSettings
    var categories: [MenuCategory]
    var items: [MenuItem]
    var sections: [MenuSection]
    var generatedAt: String
}

struct GeneratedArtifact: Identifiable {
    var id: String { name }
    var name: String
    var path: String
    var updatedAt: Date
}

enum OperationKind: String {
    case build = "Build"
    case publish = "Publish"
    case refresh = "Refresh Menu"
    case migrateImages = "Migrate Images"
}

struct OperationResult {
    var kind: OperationKind
    var success: Bool
    var details: String
    var finishedAt: Date
}

struct ImageMigrationManifest: Codable {
    struct Entry: Codable, Identifiable {
        var id: String { sourceURL }
        var sourceURL: String
        var targetURL: String
        var key: String
        var status: String
    }

    var oldPrefix: String
    var newPrefix: String
    var migratedCount: Int
    var items: [Entry]
}
