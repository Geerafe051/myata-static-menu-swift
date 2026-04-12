import Foundation

struct SourceConfiguration: Codable, Equatable {
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

    func csvURL(for gid: String) -> URL? {
        guard !googleSheetID.isEmpty, !gid.isEmpty else {
            return nil
        }

        return URL(string: "https://docs.google.com/spreadsheets/d/\(googleSheetID)/export?format=csv&gid=\(gid)")
    }

    enum CodingKeys: String, CodingKey {
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
        try container.encode(googleSheetID, forKey: .googleSheetID)
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
    var imageURL: String
    var available: Bool
    var availableOnMap: Bool
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
