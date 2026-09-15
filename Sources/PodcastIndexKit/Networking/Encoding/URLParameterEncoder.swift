import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct URLParameterEncoder: ParameterEncoder {
    /// Configures how `Array` parameters are encoded.
    enum ArrayEncoding {
        /// An empty set of square brackets is appended to the key for every value. This is the default behavior.
        case brackets
        /// No brackets are appended. The key is encoded as is.
        case noBrackets
        /// Brackets containing the item index are appended. This matches the jQuery and Node.js behavior.
        case indexInBrackets
        
        func encode(key: String, atIndex index: Int) -> String {
            switch self {
            case .brackets:
                return "\(key)[]"
            case .noBrackets:
                return key
            case .indexInBrackets:
                return "\(key)[\(index)]"
            }
        }
    }
    
    /// Configures how `Bool` parameters are encoded.
    enum BoolEncoding {
        /// Encode `true` as `1` and `false` as `0`. This is the default behavior.
        case numeric
        /// Encode `true` and `false` as string literals.
        case literal
        
        func encode(value: Bool) -> String {
            switch self {
            case .numeric:
                return value ? "1" : "0"
            case .literal:
                return value ? "true" : "false"
            }
        }
    }
    
    /// The encoding to use for `Array` parameters.
    let arrayEncoding: ArrayEncoding
    
    /// The encoding to use for `Bool` parameters.
    let boolEncoding: BoolEncoding
    
    /// The character set tp use for escaping
    let characterSet: CharacterSet
    
    init(arrayEncoding: ArrayEncoding = .brackets, boolEncoding: BoolEncoding = .numeric, characterSet: CharacterSet = .stURLQueryAllowed) {
        self.arrayEncoding = arrayEncoding
        self.boolEncoding = boolEncoding
        self.characterSet = characterSet
    }
    
    func encode(urlRequest: inout URLRequest, with parameters: Parameters) throws {
        guard let url = urlRequest.url else { throw NetworkError.missingURL }
        
        if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
            // `queryItems` leaves characters like "+" and "&" unescaped, which the index would misread
            // (e.g. a search for "c++" becomes "c  "), so escape with the stricter RFC 3986 set ourselves.
            var items = urlComponents.percentEncodedQueryItems ?? []
            items.append(contentsOf: parameters.map { URLQueryItem(name: escape($0.name), value: $0.value.map(escape)) })
            urlComponents.percentEncodedQueryItems = items
            urlRequest.url = urlComponents.url
        }
        
        if urlRequest.value(forHTTPHeaderField: "Content-Type") == nil {
            urlRequest.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        }
    }
    
    /// Creates a percent-escaped string following RFC 3986 for a query string key or value.
    ///
    /// - Parameter string: `String` to be percent-escaped.
    ///
    /// - Returns:          The percent-escaped `String`.
    func escape(_ string: String) -> String {
        string.addingPercentEncoding(withAllowedCharacters: characterSet) ?? string
    }
}
