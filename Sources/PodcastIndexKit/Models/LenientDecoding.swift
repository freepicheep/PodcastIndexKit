import Foundation

/// Enums whose raw values come from arbitrary RSS feeds.
///
/// The index passes through whatever publishers put in their feeds, so a single unexpected value
/// (e.g. an `episodeType` of "Full" or a new value destination type) used to fail decoding of the
/// *entire* response. Optional properties of these types now decode to `nil` instead.
protocol LenientDecodable: Decodable {}

extension KeyedDecodingContainer {
    func decodeIfPresent<T: LenientDecodable>(_ type: T.Type, forKey key: Key) throws -> T? {
        try? decode(T.self, forKey: key)
    }
}

extension EpisodeType: LenientDecodable {}
extension EpisodeExplicitStatus: LenientDecodable {}
extension LivestreamStatus: LenientDecodable {}
extension SocialInteractData.SocialIteractProtocol: LenientDecodable {}
extension Transcript.TranscriptType: LenientDecodable {}
extension DestinationType: LenientDecodable {}
extension ValueModelType: LenientDecodable {}
extension PodcastType: LenientDecodable {}
extension PodcastLocked: LenientDecodable {}
extension Explicitness: LenientDecodable {}
extension Rating: LenientDecodable {}
extension EntityType: LenientDecodable {}

/// Nested objects that the index sometimes sends as an empty array (`"feed": []`) when nothing matched.
extension Podcast: LenientDecodable {}
extension Episode: LenientDecodable {}
extension Value: LenientDecodable {}
extension PodcastValue: LenientDecodable {}
extension PodcastFunding: LenientDecodable {}
extension Soundbite: LenientDecodable {}
extension Transcript: LenientDecodable {}
