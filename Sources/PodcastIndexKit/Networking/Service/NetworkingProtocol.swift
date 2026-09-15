import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol Networking: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionNetworking: Networking {
    let session: URLSession

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}
