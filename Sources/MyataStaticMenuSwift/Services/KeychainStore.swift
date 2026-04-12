import Foundation
import Security

actor KeychainStore {
    private let service = "com.myata.static-menu-swift"
    private let accessKeyAccount = "s3-access-key-id"
    private let secretKeyAccount = "s3-secret-access-key"

    func loadSecrets() throws -> (accessKeyID: String, secretAccessKey: String) {
        (
            accessKeyID: try load(account: accessKeyAccount) ?? "",
            secretAccessKey: try load(account: secretKeyAccount) ?? ""
        )
    }

    func saveSecrets(accessKeyID: String, secretAccessKey: String) throws {
        try save(value: accessKeyID, account: accessKeyAccount)
        try save(value: secretAccessKey, account: secretKeyAccount)
    }

    private func load(account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess else {
            throw NSError(domain: "KeychainStore", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to read \(account) from Keychain"])
        }

        guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func save(value: String, account: String) throws {
        let data = Data(value.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecSuccess {
            return
        }

        if status != errSecItemNotFound {
            throw NSError(domain: "KeychainStore", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to update \(account) in Keychain"])
        }

        var createQuery = query
        createQuery[kSecValueData as String] = data

        let createStatus = SecItemAdd(createQuery as CFDictionary, nil)
        guard createStatus == errSecSuccess else {
            throw NSError(domain: "KeychainStore", code: Int(createStatus), userInfo: [NSLocalizedDescriptionKey: "Failed to save \(account) to Keychain"])
        }
    }
}
