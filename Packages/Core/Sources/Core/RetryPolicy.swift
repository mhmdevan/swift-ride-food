public struct RetryPolicy: Sendable {
    public let maxAttempts: Int
    public let retryableStatusCodes: Set<Int>

    public init(maxAttempts: Int = 2, retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]) {
        self.maxAttempts = max(0, maxAttempts)
        self.retryableStatusCodes = retryableStatusCodes
    }

    public func shouldRetry(statusCode: Int, attempt: Int) -> Bool {
        attempt < maxAttempts && retryableStatusCodes.contains(statusCode)
    }
}
