import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@PodcastActor
protocol NetworkRouterDelegate: AnyObject {
    func intercept(_ request: inout URLRequest) async throws
    func shouldRetry(error: Error, attempts: Int) async throws -> Bool
}

/// Describes the implementation details of a NetworkRouter
///
/// ``NetworkRouter`` is the only implementation of this protocol available to the end user, but they can create their own
/// implementations that can be used for testing for instance.
@PodcastActor
protocol NetworkRouterProtocol: AnyObject {
    associatedtype Endpoint: EndpointType
    var delegate: NetworkRouterDelegate? { get set }
    func execute<T: Decodable & Sendable>(_ route: Endpoint) async throws -> T
}

public enum NetworkError : Error, Sendable {
    case encodingFailed
    case missingURL
    case statusCode(_ statusCode: StatusCode?, data: Data)
    case noStatusCode
    case noData
    case tokenRefresh
    case notConfigured
}

typealias HTTPHeaders = [String:String]

/// A single `URLSession` shared by every router so connections to the index are pooled and reused.
enum SharedNetworking {
    static let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.httpMaximumConnectionsPerHost = 16
        return URLSession(configuration: configuration)
    }()
}

/// The NetworkRouter is a generic class that has an ``EndpointType`` and it conforms to ``NetworkRouterProtocol`
@PodcastActor
internal class NetworkRouter<Endpoint: EndpointType>: NetworkRouterProtocol {

    weak var delegate: NetworkRouterDelegate?
    let networking: Networking
    let decoder: JSONDecoder

    init(networking: Networking? = nil, decoder: JSONDecoder? = nil) {
        self.networking = networking ?? URLSessionNetworking(session: SharedNetworking.session)

        if let decoder = decoder {
            self.decoder = decoder
        } else {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            self.decoder = decoder
        }
    }

    /// This generic method will take a route and return the desired type via a network call
    /// This method is async and it can throw errors
    /// - Returns: The generic type is returned
    func execute<T: Decodable & Sendable>(_ route: Endpoint) async throws -> T {
        guard var request = try? await buildRequest(from: route) else { throw NetworkError.encodingFailed }
        try await delegate?.intercept(&request)

        let (data, response) = try await networking.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw NetworkError.noStatusCode }
        switch httpResponse.statusCode {
        case 200...299:
            return try await Self.decode(T.self, from: data, using: decoder)
        default:
            let statusCode = StatusCode(rawValue: httpResponse.statusCode)
            throw NetworkError.statusCode(statusCode, data: data)
        }
    }

    /// Decodes off `PodcastActor` so large responses don't serialize every other request behind them.
    nonisolated private static func decode<T: Decodable & Sendable>(_ type: T.Type, from data: Data, using decoder: JSONDecoder) async throws -> T {
        try decoder.decode(T.self, from: data)
    }
    
    func buildRequest(from route: Endpoint) async throws -> URLRequest {

        var request = await URLRequest(url: route.baseURL.appendingPathComponent(route.path),
                                       cachePolicy: .reloadIgnoringLocalAndRemoteCacheData,
                                       timeoutInterval: 10.0)

        request.httpMethod = route.httpMethod.rawValue
        switch await route.task {
        case .request:
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            addAdditionalHeaders(await route.headers, request: &request)
        case .requestParameters(let parameterEncoding):
            addAdditionalHeaders(await route.headers, request: &request)
            try parameterEncoding.encode(urlRequest: &request)
        }
        return request
    }

    private func addAdditionalHeaders(_ additionalHeaders: HTTPHeaders?, request: inout URLRequest) {
        guard let headers = additionalHeaders else { return }
        for (key, value) in headers {
            request.setValue(value, forHTTPHeaderField: key)
        }
    }
}
