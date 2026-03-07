import Foundation

public actor DiskOfferImageDataCache: OfferImageDataCaching {
    private let directoryURL: URL
    private let fileManager: FileManager

    public init(
        directoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let baseDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.directoryURL = baseDirectory.appendingPathComponent("offers-image-cache", isDirectory: true)
        }
    }

    public func data(for url: URL) async -> Data? {
        ensureDirectoryExistsIfNeeded()
        let fileURL = fileURL(for: url)
        return try? Data(contentsOf: fileURL)
    }

    public func insert(_ data: Data, for url: URL) async {
        ensureDirectoryExistsIfNeeded()
        let fileURL = fileURL(for: url)
        try? data.write(to: fileURL, options: .atomic)
    }

    private func ensureDirectoryExistsIfNeeded() {
        var isDirectory: ObjCBool = false
        if fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory),
           isDirectory.boolValue {
            return
        }

        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
    }

    private func fileURL(for url: URL) -> URL {
        let encoded = Data(url.absoluteString.utf8).base64EncodedString()
        let sanitized = encoded
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
        return directoryURL.appendingPathComponent(sanitized).appendingPathExtension("cache")
    }
}
