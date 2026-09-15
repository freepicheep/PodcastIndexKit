import Foundation

public final class PodcastIndexKit: Sendable {
    public init() { }

    static public func setup(apiKey: String, apiSecret: String, userAgent: String) async {
        await PodcastEnvironment.current.setup(apiKey: apiKey, apiSecret: apiSecret, userAgent: userAgent)
    }
}
