import Foundation

enum YandexYMLRenderer {
    static func render(menuData: MenuData) -> String {
        let categories = menuData.categories
            .map { "            <category id=\"\(escape($0.id))\">\(escape($0.name))</category>" }
            .joined(separator: "\n")

        let offers = menuData.items.map { item in
            let picture = item.imageURL.isEmpty ? "" : "\n                <picture>\(escape(item.imageURL))</picture>"
            let description = item.description.isEmpty ? "" : "\n                <description>\(escape(item.description))</description>"

            return """
                        <offer id="\(escape(item.id))">
                            <name>\(escape(item.name))</name>
                            <vendor>\(escape(menuData.settings.yandexVendor))</vendor>
                            <price>\(item.price)</price>
                            <currencyId>RUR</currencyId>
                            <categoryId>\(escape(item.categoryID))</categoryId>\(picture)
                            <url>\(escape(menuData.settings.menuURL))</url>\(description)
                        </offer>
                    """
        }.joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <yml_catalog>
            <shop>
                <categories>
        \(categories)
                </categories>
                <offers>
        \(offers)
                </offers>
            </shop>
        </yml_catalog>
        """
    }

    private static func escape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
