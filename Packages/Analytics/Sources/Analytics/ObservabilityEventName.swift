public enum ObservabilityEventName {
    public enum Screen {
        public static let homeViewed = "screen_home_viewed"
        public static let authViewed = "screen_auth_viewed"
        public static let ordersViewed = "screen_orders_viewed"
        public static let mapViewed = "screen_map_viewed"
        public static let offersFeedViewed = "screen_offers_feed_viewed"
        public static let offerDetailViewed = "screen_offer_detail_viewed"
    }

    public enum Action {
        public static let homeActionSelected = "home_action_selected"
        public static let retryTapped = "retry_tapped"
    }

    public enum Load {
        public static let offersFeedSample = "offers_feed_load_sample"
        public static let offersPaginationSample = "offers_pagination_sample"
    }

    public enum Error {
        public static let offersFeedFailure = "offers_feed_load_failed"
        public static let deepLinkFailed = "offers_deep_link_failed"
        public static let bgRefreshFailure = "offers_feed_refresh_failed"
    }

    public enum Retry {
        public static let offersFeedRetry = "offers_feed_retry"
        public static let offersPaginationRetry = "offers_pagination_retry"
    }

    public enum DeepLink {
        public static let routed = "offers_deep_link_routed"
        public static let requiresAuth = "offers_deep_link_requires_auth"
        public static let failed = "offers_deep_link_failed"
        public static let ignored = "offers_deep_link_ignored"
    }

    public enum BackgroundRefresh {
        public static let scheduled = "offers_background_refresh_scheduled"
        public static let scheduleFailed = "offers_background_refresh_schedule_failed"
        public static let started = "offers_feed_refresh_started"
        public static let succeeded = "offers_feed_refresh_succeeded"
        public static let failed = "offers_feed_refresh_failed"
        public static let skipped = "offers_feed_refresh_skipped"
        public static let deduplicated = "offers_feed_refresh_deduplicated"
    }

    public enum Metric {
        public static let offersFeedP50 = "offers_feed_load_p50_ms"
        public static let offersFeedP95 = "offers_feed_load_p95_ms"
        public static let offersCacheHitRatio = "offers_feed_cache_hit_ratio"
        public static let offersPaginationErrorRate = "offers_pagination_error_rate"
    }
}
