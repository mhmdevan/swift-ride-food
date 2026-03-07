import Foundation
import Testing
@testable import Networking

@Test
func decodeOrderStatusChangedEvent() throws {
    let orderID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let json = """
    {
      "type": "order_status_changed",
      "payload": {
        "order_id": "\(orderID.uuidString.lowercased())",
        "status": "in_progress"
      }
    }
    """

    let event = try WebSocketEventDecoder().decode(Data(json.utf8))

    #expect(event == .orderStatusChanged(orderID: orderID, status: "in_progress"))
}

@Test
func decodeDriverLocationChangedEvent() throws {
    let orderID = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
    let json = """
    {
      "type": "driver_location_changed",
      "payload": {
        "order_id": "\(orderID.uuidString.lowercased())",
        "latitude": 55.75,
        "longitude": 37.61
      }
    }
    """

    let event = try WebSocketEventDecoder().decode(Data(json.utf8))

    #expect(event == .driverLocationChanged(orderID: orderID, latitude: 55.75, longitude: 37.61))
}

@Test
func decodeFailsForUnknownEventType() {
    let json = """
    {
      "type": "unknown",
      "payload": {
        "order_id": "11111111-1111-1111-1111-111111111111"
      }
    }
    """

    do {
        _ = try WebSocketEventDecoder().decode(Data(json.utf8))
        Issue.record("Expected decoder to fail")
    } catch let error as NetworkError {
        #expect(error == .decoding(message: "Unsupported WebSocket event type: unknown"))
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}

@Test
func decodeFailsWhenOrderStatusIsMissing() {
    let json = """
    {
      "type": "order_status_changed",
      "payload": {
        "order_id": "11111111-1111-1111-1111-111111111111"
      }
    }
    """

    do {
        _ = try WebSocketEventDecoder().decode(Data(json.utf8))
        Issue.record("Expected decoder to fail")
    } catch let error as NetworkError {
        #expect(error == .decoding(message: "Missing status in order_status_changed event"))
    } catch {
        Issue.record("Unexpected error type: \(error)")
    }
}
