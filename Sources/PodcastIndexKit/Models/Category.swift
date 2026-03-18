public struct PodcastCategory: Codable, Hashable, Identifiable, Sendable {
	/// The internal PodcastIndex.org category ID.
	public let id: Int?

	/// The category name.
	public let name: String?

    public init(id: Int? = nil, name: String? = nil) {
        self.id = id
        self.name = name
    }
}

/// Type alias for backwards compatibility
@available(*, deprecated, renamed: "PodcastCategory")
public typealias Category = PodcastCategory
