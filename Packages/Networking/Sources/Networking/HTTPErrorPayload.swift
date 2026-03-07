import Foundation

struct HTTPErrorPayload: Decodable {
    let message: String?
    let error: String?
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case message
        case error
        case errorDescription = "error_description"
    }

    var resolvedMessage: String? {
        if let message, message.isEmpty == false {
            return message
        }

        if let errorDescription, errorDescription.isEmpty == false {
            return errorDescription
        }

        if let error, error.isEmpty == false {
            return error
        }

        return nil
    }
}
