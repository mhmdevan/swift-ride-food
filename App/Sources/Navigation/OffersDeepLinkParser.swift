import Foundation

enum OffersDeepLinkSource: String, Equatable {
    case customScheme
    case universalLink
}

struct OffersDeepLinkTarget: Equatable {
    let offerID: UUID
    let source: OffersDeepLinkSource
}

enum OffersDeepLinkFailureReason: String, Equatable {
    case invalidScheme
    case invalidHost
    case invalidPath
    case invalidOfferIdentifier
}

extension OffersDeepLinkFailureReason {
    var userMessage: String {
        switch self {
        case .invalidScheme, .invalidHost, .invalidPath:
            return "This offer link is invalid or unsupported."
        case .invalidOfferIdentifier:
            return "This offer link has an invalid identifier."
        }
    }
}

enum OffersDeepLinkParseResult: Equatable {
    case notApplicable
    case failure(OffersDeepLinkFailureReason)
    case target(OffersDeepLinkTarget)
}

protocol OffersDeepLinkParsing {
    func parse(_ url: URL) -> OffersDeepLinkParseResult
}

struct OffersDeepLinkParser: OffersDeepLinkParsing {
    func parse(_ url: URL) -> OffersDeepLinkParseResult {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let scheme = components.scheme?.lowercased() else {
            return .failure(.invalidScheme)
        }

        if scheme == OffersDeepLinkContract.customScheme {
            return parseCustomScheme(components: components)
        }

        if let host = components.host?.lowercased(),
           host == OffersDeepLinkContract.universalLinkHost {
            if scheme != OffersDeepLinkContract.universalLinkScheme {
                return .failure(.invalidScheme)
            }
            return parseUniversalLink(components: components)
        }

        return .notApplicable
    }

    private func parseCustomScheme(components: URLComponents) -> OffersDeepLinkParseResult {
        guard components.host?.lowercased() == OffersDeepLinkContract.customHost else {
            return .failure(.invalidHost)
        }

        let pathComponents = normalizedPathComponents(components.path)
        guard pathComponents.count == 1 else {
            return .failure(.invalidPath)
        }

        guard let offerID = UUID(uuidString: pathComponents[0]) else {
            return .failure(.invalidOfferIdentifier)
        }

        return .target(OffersDeepLinkTarget(offerID: offerID, source: .customScheme))
    }

    private func parseUniversalLink(components: URLComponents) -> OffersDeepLinkParseResult {
        let pathComponents = normalizedPathComponents(components.path)
        guard pathComponents.count == 2 else {
            return .failure(.invalidPath)
        }
        guard pathComponents[0].lowercased() == OffersDeepLinkContract.offersPathComponent else {
            return .failure(.invalidPath)
        }
        guard let offerID = UUID(uuidString: pathComponents[1]) else {
            return .failure(.invalidOfferIdentifier)
        }

        return .target(OffersDeepLinkTarget(offerID: offerID, source: .universalLink))
    }

    private func normalizedPathComponents(_ path: String) -> [String] {
        path.split(separator: "/")
            .map(String.init)
            .filter { $0.isEmpty == false }
    }
}

enum OffersDeepLinkRoutingResult: Equatable {
    case notHandled
    case routed(offerID: UUID)
    case requiresAuthentication(offerID: UUID)
    case failed(OffersDeepLinkFailureReason)
}
