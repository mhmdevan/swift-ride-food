import Testing
@testable import Core

@Test
func shouldRetryWhenStatusCodeIsRetryableAndAttemptsNotExceeded() {
    let policy = RetryPolicy(maxAttempts: 2, retryableStatusCodes: [500])

    #expect(policy.shouldRetry(statusCode: 500, attempt: 0))
}

@Test
func shouldNotRetryWhenStatusCodeIsNotRetryable() {
    let policy = RetryPolicy(maxAttempts: 3, retryableStatusCodes: [500])

    #expect(policy.shouldRetry(statusCode: 401, attempt: 0) == false)
}

@Test
func shouldNotRetryWhenAttemptsExceeded() {
    let policy = RetryPolicy(maxAttempts: 1, retryableStatusCodes: [500])

    #expect(policy.shouldRetry(statusCode: 500, attempt: 1) == false)
}
