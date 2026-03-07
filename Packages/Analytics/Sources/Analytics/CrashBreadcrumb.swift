public struct CrashBreadcrumb: Equatable, Sendable {
    public let message: String
    public let category: String
    public let metadata: [String: String]

    public init(message: String, category: String, metadata: [String: String] = [:]) {
        self.message = message
        self.category = category
        self.metadata = metadata
    }
}
