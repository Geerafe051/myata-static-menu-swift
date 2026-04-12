import Foundation

enum CSVParser {
    static func parse(_ source: String) -> [[String: String]] {
        let normalized = source
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else { return [] }

        let lines = normalized.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        guard let headerLine = lines.first else { return [] }
        let headers = splitCSVLine(headerLine).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        return lines.dropFirst().map { line in
            let cells = splitCSVLine(line)
            var row: [String: String] = [:]

            for (index, header) in headers.enumerated() {
                row[header] = index < cells.count ? cells[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            }

            return row
        }
    }

    private static func splitCSVLine(_ line: String) -> [String] {
        var values: [String] = []
        var current = ""
        var inQuotes = false
        let characters = Array(line)
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
                values.append(current)
                current = ""
            } else {
                current.append(character)
            }

            index += 1
        }

        values.append(current)
        return values
    }
}
