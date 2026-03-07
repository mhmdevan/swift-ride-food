import Foundation

public protocol FixtureLoading: Sendable {
    func loadFixture(named name: String) throws -> Data
}

public struct BundleFixtureLoader: FixtureLoading {
    public init() {}

    public func loadFixture(named name: String) throws -> Data {
        let directURL = Bundle.module.url(forResource: name, withExtension: "json")
        let nestedURL = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Resources/Fixtures")
        let legacyNestedURL = Bundle.module.url(forResource: name, withExtension: "json", subdirectory: "Fixtures")

        guard let url = directURL ?? nestedURL ?? legacyNestedURL else {
            throw NetworkError.transport(message: "Missing fixture: \(name).json")
        }

        return try Data(contentsOf: url)
    }
}
