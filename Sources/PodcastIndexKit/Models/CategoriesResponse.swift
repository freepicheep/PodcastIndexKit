public struct CategoriesResponse: Codable, Hashable, Sendable {
	private let responseStatus: String?
	
	/// Indicates API request status
	/// Allowed: true┃false
	public var status: Bool {
		switch responseStatus?.lowercased() {
		case "true": return true
		case "false": return false
		default: return false
		}
	}
	
	/// List of categories
	public let feeds: [PodcastCategory]?
	
	/// Number of items returned in request
	public let count: Int?
	
	/// Description of the response
	public let categoriesResponseDescription: String?
	
	enum CodingKeys: String, CodingKey {
		case responseStatus = "status"
		case feeds
		case count
		case categoriesResponseDescription = "description"
	}
    
    public init(responseStatus: String?, feeds: [PodcastCategory]?, count: Int?, categoriesResponseDescription: String?) {
        self.responseStatus = responseStatus
        self.feeds = feeds
        self.count = count
        self.categoriesResponseDescription = categoriesResponseDescription
    }
}
