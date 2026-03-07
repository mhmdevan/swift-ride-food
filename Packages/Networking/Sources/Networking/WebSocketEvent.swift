import Foundation

public enum WebSocketEvent: Equatable, Sendable {
    case orderStatusChanged(orderID: UUID, status: String)
    case driverLocationChanged(orderID: UUID, latitude: Double, longitude: Double)
}

private struct WebSocketEnvelopeDTO: Decodable {
    let type: String
    let payload: PayloadDTO

    struct PayloadDTO: Decodable {
        let orderID: UUID
        let status: String?
        let latitude: Double?
        let longitude: Double?

        enum CodingKeys: String, CodingKey {
            case orderID = "order_id"
            case status
            case latitude
            case longitude
        }
    }
}

public struct WebSocketEventDecoder: Sendable {
    public init() {}

    public func decode(_ data: Data) throws -> WebSocketEvent {
        let envelope = try JSONDecoder.networkDefault.decode(WebSocketEnvelopeDTO.self, from: data)

        switch envelope.type {
        case "order_status_changed":
            guard let status = envelope.payload.status else {
                throw NetworkError.decoding(message: "Missing status in order_status_changed event")
            }
            return .orderStatusChanged(orderID: envelope.payload.orderID, status: status)

        case "driver_location_changed":
            guard let latitude = envelope.payload.latitude,
                  let longitude = envelope.payload.longitude else {
                throw NetworkError.decoding(message: "Missing coordinates in driver_location_changed event")
            }
            return .driverLocationChanged(
                orderID: envelope.payload.orderID,
                latitude: latitude,
                longitude: longitude
            )

        default:
            throw NetworkError.decoding(message: "Unsupported WebSocket event type: \(envelope.type)")
        }
    }
}
