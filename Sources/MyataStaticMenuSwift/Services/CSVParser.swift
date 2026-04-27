import Foundation

enum CSVParser {
    static func parse(_ source: String) -> [[String: String]] {
        let normalized = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return [] }

        let rows = splitCSVRows(normalized)
        guard let headerRow = rows.first else { return [] }
        let headers = headerRow.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return rows.dropFirst().map { cells in
            var row: [String: String] = [:]

            for (index, header) in headers.enumerated() {
                row[header] = index < cells.count ? cells[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            }

            return row
        }
    }

    private static func splitCSVRows(_ source: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var current = ""
        var inQuotes = false
        let characters = Array(source)
        var index = 0

        while index < characters.count {
            let character = characters[index]
            let next = index + 1 < characters.count ? characters[index + 1] : nil

            if character == "\"" {
                if inQuotes, next == "\"" {
                    current.append("\"")
                    index += 1
                } else {
                    inQuotes.toggle()
                }
            } else if character == ",", !inQuotes {
                currentRow.append(current)
                current = ""
            } else if character == "\n", !inQuotes {
                currentRow.append(current)
                rows.append(currentRow)
                currentRow = []
                current = ""
            } else {
                current.append(character)
            }

            index += 1
        }

        currentRow.append(current)
        rows.append(currentRow)
        return rows
    }
}
