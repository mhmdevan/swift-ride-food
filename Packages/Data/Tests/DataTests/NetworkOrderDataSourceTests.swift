import Core
import Foundation
import Networking
import Testing
@testable import Data

private func makeHTTPClient() throws -> URLSessionHTTPClient {
    let baseURL = try #require(URL(string: "https://api.swiftridefood.com"))
    return URLSessionHTTPClient(
        baseURL: baseURL,
        transport: FixtureMockHTTPTransport(latencyNanoseconds: 0)
    )
}

@Test
func fetchOrdersDecodesFixturePayload() async throws {
    let dataSource = NetworkOrderDataSource(httpClient: try makeHTTPClient())

    let orders = try await dataSource.fetchOrders()

    #expect(orders.count == 3)
    #expect(orders.first?.status == .inProgress)
    #expect(orders.first?.title == "Food Delivery #1001")
}

@Test
func fetchOrderReturnsOrderDetailsForKnownID() async throws {
    let dataSource = NetworkOrderDataSource(httpClient: try makeHTTPClient())
    let id = try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))

    let order = try await dataSource.fetchOrder(id: id)

    #expect(order.id == id)
    #expect(order.title == "Food Delivery #1001")
}

@Test
func fetchOrderMapsNotFoundToAppError() async throws {
    let dataSource = NetworkOrderDataSource(httpClient: try makeHTTPClient())
    let id = UUID()

    do {
        _ = try await dataSource.fetchOrder(id: id)
        Issue.record("Expected fetch order to fail")
    } catch let error as AppError {
        #expect(error.errorDescription == "Requested resource was not found")
    }
}
