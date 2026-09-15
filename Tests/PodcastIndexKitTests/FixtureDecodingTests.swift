import Foundation
import Testing
@testable import PodcastIndexKit

/// Decodes the example responses from PodcastIndex's OpenAPI spec
/// (https://github.com/Podcastindex-org/docs-api), one per endpoint the kit wraps.
@Suite struct FixtureDecodingTests {
    func fixture<T: Decodable>(_ name: String, as type: T.Type) throws -> T {
        let url = try #require(Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures"))
        return try JSONDecoder.podcastIndexDecoder.decode(T.self, from: Data(contentsOf: url))
    }

    @Test func episodesByFeedID() throws {
        let response = try fixture("episodes_byfeedid", as: EpisodeArrayResponse.self)
        #expect(response.status)
        let episode = try #require(response.items?.first)
        #expect(episode.id != nil)
        #expect(episode.enclosureUrl != nil)
        #expect(episode.datePublished != nil)
    }

    @Test func episodeByID() throws {
        let response = try fixture("episodes_byid", as: EpisodeResponse.self)
        #expect(response.id == "16795088")
        let episode = try #require(response.episode)
        #expect(episode.id == 16795088)
        #expect(episode.episodeType == .full)
        #expect(episode.persons?.first?.name == "Dave Jones")
        #expect(episode.value?.destinations?.first?.type == .node)
        #expect(episode.soundbite?.duration == 40)
        #expect(episode.transcripts?.first?.transcriptType == .srtApplication || episode.transcripts?.first?.type == "application/srt")
    }

    @Test func episodeByGUID() throws {
        let response = try fixture("episodes_byguid", as: EpisodeResponse.self)
        #expect(response.id == "920666")
        #expect(response.episode?.id != nil)
    }

    @Test func randomRecentLiveAndPersonEpisodes() throws {
        for name in ["episodes_random", "recent_episodes", "search_byperson"] {
            let response = try fixture(name, as: EpisodeArrayResponse.self)
            #expect(response.items?.isEmpty == false, "\(name) had no items")
        }
        let live = try fixture("episodes_live", as: EpisodeArrayResponse.self)
        #expect((live.liveItems ?? live.items)?.isEmpty == false)
    }

    @Test func podcastLookups() throws {
        for name in ["podcasts_byfeedid", "podcasts_byguid"] {
            let response = try fixture(name, as: PodcastResponse.self)
            let feed = try #require(response.feed, "\(name) feed failed to decode")
            #expect(feed.id != nil)
            #expect(feed.title != nil)
        }
    }

    @Test func podcastLists() throws {
        for name in ["podcasts_trending", "bymedium", "recent_feeds", "recent_newfeeds", "search_byterm"] {
            let response = try fixture(name, as: PodcastArrayResponse.self)
            #expect(!response.feeds.isEmpty, "\(name) had no feeds")
            #expect(response.feeds.first?.id != nil, "\(name) feed had no id")
        }
    }

    @Test func miscellaneous() throws {
        #expect(try fixture("categories_list", as: CategoriesResponse.self).feeds?.first?.name != nil)
        #expect(try fixture("recent_soundbites", as: SoundbiteArrayResponse.self).items?.first?.enclosureUrl != nil)
        #expect(try fixture("stats_current", as: StatsResponse.self).stats?.feedCountTotal != nil)
        #expect(try fixture("value_byfeedid", as: ValueResponse.self).value?.destinations?.isEmpty == false)
        #expect(try fixture("hub_pubnotify", as: PubNotifyResponse.self).status)
    }
}
