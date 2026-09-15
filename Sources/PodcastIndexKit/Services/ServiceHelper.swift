import Foundation

func append(_ any: Any?, toParameters parameters: inout Parameters, withKey key: String) {
    guard let any else { return }
    switch any {
    case let date as Date:
        // The index expects unix epoch seconds, not Date's description ("2024-01-01 00:00:00 +0000").
        updateParamters(&parameters, with: (key, String(Int(date.timeIntervalSince1970))))
    default:
        updateParamters(&parameters, with: (key, "\(any)"))
    }
}

func appendNil(toParameters paramters: inout Parameters, withKey key: String, forBool bool: Bool) {
    guard bool else { return }
    updateParamters(&paramters, with: (key, nil))
}

fileprivate func updateParamters(_ paramters: inout Parameters, with dataToAppend: (String, String?)) {
    paramters.append(URLQueryItem(name: dataToAppend.0, value: dataToAppend.1))
}
