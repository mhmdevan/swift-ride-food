import Core
import Foundation
import Networking

public actor NetworkOrderDataSource: RemoteOrderDataSource {
    private let httpClient: any HTTPClient

    public init(httpClient: any HTTPClient) {
        self.httpClient = httpClient
    }

    public func fetchOrders() async throws -> [Order] {
        do {
            let endpoint = APIEndpoints.orders()
            let response: [OrderDTO] = try await httpClient.send(endpoint)
            return response.map { $0.toDomain() }
        } catch let error as NetworkError {
            throw error.asAppError
        } catch {
            throw AppError.unknown
        }
    }

    public func fetchOrder(id: UUID) async throws -> Order {
        do {
            let endpoint = APIEndpoints.order(id: id)
            let response: OrderDTO = try await httpClient.send(endpoint)
            return response.toDomain()
        } catch let error as NetworkError {
            throw error.asAppError
        } catch {
            throw AppError.unknown
        }
    }

    public func createOrder(title: String) async throws -> Order {
        Order(title: title, status: .pending)
    }
}
