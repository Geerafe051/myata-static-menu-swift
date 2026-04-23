import CryptoKit
import Foundation

struct S3Client {
    private let configuration: SourceConfiguration
    private let iso8601BasicFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
        return formatter
    }()

    private let dateScopeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    init(configuration: SourceConfiguration) {
        self.configuration = configuration
    }

    func upload(data: Data, key: String, contentType: String, cacheControl: String) async throws -> URL {
        guard
            !configuration.s3Endpoint.isEmpty,
            !configuration.s3Region.isEmpty,
            !configuration.bucket.isEmpty,
            !configuration.accessKeyID.isEmpty,
            !configuration.secretAccessKey.isEmpty
        else {
            throw NSError(domain: "S3Client", code: 1, userInfo: [NSLocalizedDescriptionKey: "S3 configuration is incomplete"])
        }

        guard var endpoint = URL(string: configuration.s3Endpoint) else {
            throw NSError(domain: "S3Client", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid S3 endpoint"])
        }

        if endpoint.path.isEmpty {
            endpoint.append(path: configuration.bucket)
        } else {
            endpoint.append(path: configuration.bucket)
        }
        endpoint.append(path: key)

        let now = Date()
        let amzDate = iso8601BasicFormatter.string(from: now)
        let dateStamp = dateScopeFormatter.string(from: now)
        let payloadHash = sha256Hex(data)
        let host = endpoint.host() ?? "storage.yandexcloud.net"
        let canonicalURI = "/\(configuration.bucket)/" + key.split(separator: "/").joined(separator: "/")

        let canonicalHeaders = [
            "content-type:\(contentType)",
            "host:\(host)",
            "x-amz-acl:public-read",
            "x-amz-content-sha256:\(payloadHash)",
            "x-amz-date:\(amzDate)",
        ].joined(separator: "\n") + "\n"

        let signedHeaders = "content-type;host;x-amz-acl;x-amz-content-sha256;x-amz-date"
        let canonicalRequest = [
            "PUT",
            canonicalURI,
            "",
            canonicalHeaders,
            signedHeaders,
            payloadHash,
        ].joined(separator: "\n")

        let credentialScope = "\(dateStamp)/\(configuration.s3Region)/s3/aws4_request"
        let stringToSign = [
            "AWS4-HMAC-SHA256",
            amzDate,
            credentialScope,
            sha256Hex(Data(canonicalRequest.utf8)),
        ].joined(separator: "\n")

        let signingKey = signatureKey(
            secret: configuration.secretAccessKey,
            dateStamp: dateStamp,
            region: configuration.s3Region,
            service: "s3"
        )
        let signature = hmacHex(key: signingKey, data: Data(stringToSign.utf8))
        let authorization = "AWS4-HMAC-SHA256 Credential=\(configuration.accessKeyID)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        request.setValue("public-read", forHTTPHeaderField: "x-amz-acl")
        request.setValue(payloadHash, forHTTPHeaderField: "x-amz-content-sha256")
        request.setValue(amzDate, forHTTPHeaderField: "x-amz-date")
        request.setValue(cacheControl, forHTTPHeaderField: "Cache-Control")
        request.setValue(authorization, forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200..<300).contains(httpResponse.statusCode) else {
            throw NSError(domain: "S3Client", code: 3, userInfo: [NSLocalizedDescriptionKey: "S3 upload failed for \(key)"])
        }

        return publicURL(for: key)
    }

    func objectExists(key: String) async throws -> Bool {
        var request = URLRequest(url: publicURL(for: key))
        request.httpMethod = "HEAD"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "S3Client", code: 4, userInfo: [NSLocalizedDescriptionKey: "Unexpected response while checking \(key)"])
        }

        switch httpResponse.statusCode {
        case 200:
            return true
        case 404:
            return false
        default:
            throw NSError(domain: "S3Client", code: 5, userInfo: [NSLocalizedDescriptionKey: "S3 existence check failed for \(key)"])
        }
    }

    func publicURL(for key: String) -> URL {
        URL(string: "\(configuration.s3Endpoint)/\(configuration.bucket)/\(key)")!
    }

    private func signatureKey(secret: String, dateStamp: String, region: String, service: String) -> Data {
        let secretData = Data(("AWS4" + secret).utf8)
        let dateKey = hmac(key: secretData, data: Data(dateStamp.utf8))
        let regionKey = hmac(key: dateKey, data: Data(region.utf8))
        let serviceKey = hmac(key: regionKey, data: Data(service.utf8))
        return hmac(key: serviceKey, data: Data("aws4_request".utf8))
    }

    private func hmac(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let digest = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(digest)
    }

    private func hmacHex(key: Data, data: Data) -> String {
        hmac(key: key, data: data).map { String(format: "%02x", $0) }.joined()
    }

    private func sha256Hex(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
}
