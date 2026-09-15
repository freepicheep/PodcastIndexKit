import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CryptoKit)
import CryptoKit
#else
import Crypto
#endif

extension JSONDecoder {
    static var podcastIndexDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // The index sends unix timestamps. Most are integers, but some fields (e.g. soundbite start times)
        // are floating point and a few feeds send numeric strings, so accept all three.
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            if let seconds = try? container.decode(Int.self) {
                return Date(timeIntervalSince1970: TimeInterval(seconds))
            }
            if let seconds = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: seconds)
            }
            if let string = try? container.decode(String.self), let seconds = Double(string) {
                return Date(timeIntervalSince1970: seconds)
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected a unix timestamp")
        }

        return decoder
    }
}

extension JSONEncoder {
    static var podcastIndexEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        return encoder
    }
}

@PodcastActor
class PodcastIndexRouterDelegate: NetworkRouterDelegate {
    func shouldRetry(error: any Error, attempts: Int) async throws -> Bool {
        false
    }

    func intercept(_ request: inout URLRequest) async throws {
        guard let apiKey = PodcastEnvironment.current.apiKey, let apiSecret = PodcastEnvironment.current.apiSecret, let userAgent = PodcastEnvironment.current.userAgent else {
            // You must call the static setup(apiKey: String, apiSecret: String, userAgent: String) method before using the framework
            throw NetworkError.notConfigured
        }

        let headers = PodcastIndexAuth.headers(apiKey: apiKey, apiSecret: apiSecret, userAgent: userAgent)
        for (field, value) in headers {
            request.setValue(value, forHTTPHeaderField: field)
        }
    }
}

enum PodcastIndexAuth {
    /// Builds the headers the index requires: `Authorization` is the SHA-1 of key + secret + unix time.
    static func headers(apiKey: String, apiSecret: String, userAgent: String, date: Date = Date()) -> [String: String] {
        let apiHeaderTime = String(Int(date.timeIntervalSince1970))
        let hashed = Insecure.SHA1.hash(data: Data((apiKey + apiSecret + apiHeaderTime).utf8))
        let hashString = hashed.map { String(format: "%02x", $0) }.joined()

        return [
            "X-Auth-Date": apiHeaderTime,
            "X-Auth-Key": apiKey,
            "Authorization": hashString,
            "User-Agent": userAgent,
        ]
    }
}
