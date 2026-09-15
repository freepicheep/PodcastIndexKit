import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Testing
@testable import PodcastIndexKit

@Suite struct DecodingTests {
    let decoder = JSONDecoder.podcastIndexDecoder

    @Test func unknownEnumValuesDecodeToNil() throws {
        let json = #"""
        {"status":"true","items":[{"id":1,"title":"Ep","episodeType":"Full","explicit":7,"datePublished":1700000000}],"count":1}
        """#
        let response = try decoder.decode(EpisodeArrayResponse.self, from: Data(json.utf8))
        let episode = try #require(response.items?.first)
        #expect(episode.id == 1)
        #expect(episode.episodeType == nil)
        #expect(episode.explicit == nil)
        #expect(episode.datePublished == Date(timeIntervalSince1970: 1700000000))
    }

    @Test func emptyArrayForMissingFeedDecodesToNil() throws {
        let json = #"{"status":"true","query":{"id":"0"},"feed":[],"description":"No feeds match this id."}"#
        let response = try decoder.decode(PodcastResponse.self, from: Data(json.utf8))
        #expect(response.status)
        #expect(response.feed == nil)
    }

    @Test func emptyArrayForMissingEpisodeDecodesToNil() throws {
        let json = #"{"status":"true","id":"0","episode":[],"description":"No episodes match this id."}"#
        let response = try decoder.decode(EpisodeResponse.self, from: Data(json.utf8))
        #expect(response.episode == nil)
    }

    @Test func fractionalTimestampsDecode() throws {
        let json = #"{"status":"true","count":1,"items":[{"startTime":12.5,"duration":30,"episodeId":2}]}"#
        let response = try decoder.decode(SoundbiteArrayResponse.self, from: Data(json.utf8))
        #expect(response.items?.first?.startTime == Date(timeIntervalSince1970: 12.5))
    }

    @Test func personSearchDecodesEpisodes() throws {
        let json = #"{"status":"true","items":[{"id":9,"title":"Interview","feedId":3}],"count":1,"query":"adam curry"}"#
        let response = try decoder.decode(EpisodeArrayResponse.self, from: Data(json.utf8))
        #expect(response.items?.first?.feedId == 3)
    }
}

@Suite struct RequestTests {
    @Test func queryValuesAreStrictlyEscaped() throws {
        var request = URLRequest(url: URL(string: "https://api.podcastindex.org/api/1.0/search/byterm")!)
        try URLParameterEncoder().encode(urlRequest: &request, with: [
            URLQueryItem(name: "q", value: "c++ & rust"),
            URLQueryItem(name: "clean", value: nil),
        ])
        #expect(request.url?.absoluteString == "https://api.podcastindex.org/api/1.0/search/byterm?q=c%2B%2B%20%26%20rust&clean")
    }

    @Test func datesAreSentAsEpochSeconds() {
        var parameters: [URLQueryItem] = []
        append(Date(timeIntervalSince1970: 1700000000), toParameters: &parameters, withKey: "since")
        #expect(parameters == [URLQueryItem(name: "since", value: "1700000000")])
    }

    @Test func authHeadersMatchIndexSpec() {
        let headers = PodcastIndexAuth.headers(apiKey: "key", apiSecret: "secret", userAgent: "Test/1.0", date: Date(timeIntervalSince1970: 1700000000))
        #expect(headers["X-Auth-Date"] == "1700000000")
        #expect(headers["X-Auth-Key"] == "key")
        #expect(headers["User-Agent"] == "Test/1.0")
        // sha1("keysecret1700000000")
        #expect(headers["Authorization"] == "abaf71c02050c31e4d4e6b08c1625173af0445ba")
    }
}
