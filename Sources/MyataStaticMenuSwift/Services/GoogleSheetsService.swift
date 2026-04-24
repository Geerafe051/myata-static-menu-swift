import Foundation

struct GoogleSheetsService {
    func loadMenuData(using configuration: SourceConfiguration) async throws -> MenuData {
        let settingsRows = try await fetchRows(
            from: [
                configuration.csvURL(forSheetNamed: "Settings"),
                configuration.legacyCSVURL(for: configuration.settingsGID),
            ],
            name: "Settings"
        )
        let categoryRows = try await fetchRows(
            from: [
                configuration.csvURL(forSheetNamed: "Categories"),
                configuration.legacyCSVURL(for: configuration.categoriesGID),
            ],
            name: "Categories"
        )
        let itemRows = try await fetchRows(
            from: [
                configuration.csvURL(forSheetNamed: "Items"),
                configuration.legacyCSVURL(for: configuration.itemsGID),
            ],
            name: "Items"
        )

        let settings = mapSettings(settingsRows, configuration: configuration)
        let categories = mapCategories(categoryRows)
        let items = mapItems(itemRows)
        let sections = categories
            .map { category in
                MenuSection(category: category, items: items.filter { $0.categoryID == category.id })
            }
            .filter { !$0.items.isEmpty }

        return MenuData(
            settings: settings,
            categories: categories,
            items: items,
            sections: sections,
            generatedAt: ISO8601DateFormatter().string(from: Date())
        )
    }

    private func fetchRows(from urls: [URL?], name: String) async throws -> [[String: String]] {
        let candidates = urls.compactMap { $0 }
        guard !candidates.isEmpty else {
            throw NSError(domain: "GoogleSheetsService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing CSV URL for \(name)"])
        }

        var lastError: Error?

        for url in candidates {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
                    throw NSError(domain: "GoogleSheetsService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch \(name) CSV"])
                }

                guard let source = String(data: data, encoding: .utf8) else {
                    throw NSError(domain: "GoogleSheetsService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to decode \(name) CSV"])
                }

                return CSVParser.parse(source)
            } catch {
                lastError = error
            }
        }

        throw lastError ?? NSError(domain: "GoogleSheetsService", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to load \(name) CSV"])
    }

    private func mapSettings(_ rows: [[String: String]], configuration: SourceConfiguration) -> MenuSettings {
        let row = rows.first ?? [:]
        return MenuSettings(
            venueName: row["venue_name"] ?? configuration.yandexVendor,
            subtitle: row["subtitle"] ?? "",
            description: row["description"] ?? "",
            logoURL: row["logo"] ?? "",
            faviconURL: row["favicon"] ?? "",
            address: row["address"] ?? "",
            phone: row["phone"] ?? "",
            instagram: row["instagram"] ?? "",
            menuURL: row["menu_url"].flatMap { $0.isEmpty ? nil : $0 } ?? configuration.publicMenuURL,
            yandexVendor: row["yandex_vendor"].flatMap { $0.isEmpty ? nil : $0 } ?? (row["venue_name"] ?? configuration.yandexVendor)
        )
    }

    private func mapCategories(_ rows: [[String: String]]) -> [MenuCategory] {
        rows.compactMap { row in
            guard
                let id = row["id"], !id.isEmpty,
                let name = row["name"], !name.isEmpty
            else { return nil }

            return MenuCategory(
                id: id,
                name: name,
                sortOrder: Int(row["sort_order"] ?? "") ?? 0,
                visible: parseBool(row["visible"], defaultValue: true)
            )
        }
        .filter(\.visible)
        .sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private func mapItems(_ rows: [[String: String]]) -> [MenuItem] {
        rows.compactMap { row in
            guard
                let id = row["id"], !id.isEmpty,
                let categoryID = row["category_id"], !categoryID.isEmpty,
                let name = row["name"], !name.isEmpty
            else { return nil }

            return MenuItem(
                id: id,
                categoryID: categoryID,
                name: name,
                price: Int((row["price"] ?? "").replacingOccurrences(of: " ", with: "")) ?? 0,
                description: row["description"] ?? "",
                calories: cleanValue(row["calories"]),
                proteins: cleanValue(row["proteins"]),
                fats: cleanValue(row["fats"]),
                carbohydrates: cleanValue(row["carbohydrates"]),
                portion: portionValue(from: row, itemName: name),
                imageURL: row["image_url"] ?? "",
                available: parseBool(row["available"], defaultValue: true),
                availableOnMap: parseBool(row["available_on_map"], defaultValue: false),
                showNutritionFacts: parseBool(row["show_NF"], defaultValue: false),
                sortOrder: Int(row["sort_order"] ?? "") ?? 0
            )
        }
        .filter(\.available)
        .sorted {
            if $0.sortOrder == $1.sortOrder {
                return $0.name.localizedCompare($1.name) == .orderedAscending
            }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private func cleanValue(_ value: String?) -> String {
        value?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func portionValue(from row: [String: String], itemName: String) -> String {
        let explicitValue = [
            row["portion"],
            row["weight"],
            row["mass"],
            row["volume"],
            row["serving"],
        ]
        .compactMap { cleanValue($0) }
        .first { !$0.isEmpty }

        if let explicitValue {
            return explicitValue
        }

        let portion = inferredPortion(from: itemName)
        return portion.isEmpty ? inferredDrinkVolume(from: itemName) : portion
    }

    private func inferredPortion(from itemName: String) -> String {
        let pattern = #"(?i)(\d+(?:[,.]\d+)?)\s*(мл|л|г|кг)\.?"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ""
        }

        let range = NSRange(itemName.startIndex..<itemName.endIndex, in: itemName)
        guard let match = regex.matches(in: itemName, range: range).last else {
            return ""
        }

        guard
            let valueRange = Range(match.range(at: 1), in: itemName),
            let unitRange = Range(match.range(at: 2), in: itemName)
        else {
            return ""
        }

        return "\(itemName[valueRange]) \(itemName[unitRange])"
    }

    private func inferredDrinkVolume(from itemName: String) -> String {
        let pattern = #"\b(0[,.]\d{1,2})\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return ""
        }

        let range = NSRange(itemName.startIndex..<itemName.endIndex, in: itemName)
        guard
            let match = regex.matches(in: itemName, range: range).last,
            let valueRange = Range(match.range(at: 1), in: itemName)
        else {
            return ""
        }

        return "\(itemName[valueRange]) л"
    }

    private func parseBool(_ value: String?, defaultValue: Bool) -> Bool {
        guard let value else { return defaultValue }
        switch value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "true", "yes", "y", "да":
            return true
        case "0", "false", "no", "n", "нет":
            return false
        default:
            return defaultValue
        }
    }
}
