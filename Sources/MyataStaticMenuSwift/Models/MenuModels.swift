import Foundation

struct SourceConfiguration: Codable, Equatable {
    var googleSheetID: String = "1s4R3MAhKlQLbCyy-AFl9QISEviAcgik5fxkwPpD_lUc"
    var settingsGID: String = "1486340064"
    var categoriesGID: String = "0"
    var itemsGID: String = "823879448"
    var bucket: String = "hookah-menu-feed"
    var prefix: String = "menu"
    var publicMenuURL: String = "https://storage.yandexcloud.net/hookah-menu-feed/menu/index.html"
    var yandexVendor: String = "Мята Ленинский"

    func csvURL(for gid: String) -> URL? {
        guard !googleSheetID.isEmpty, !gid.isEmpty else {
            return nil
        }

        return URL(string: "https://docs.google.com/spreadsheets/d/\(googleSheetID)/export?format=csv&gid=\(gid)")
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
