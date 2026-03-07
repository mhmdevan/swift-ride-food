import Foundation

struct LoginRequestDTO: Codable {
    let email: String
    let password: String
}

struct LoginResponseDTO: Codable {
    let token: String
    let userID: String
    let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case token
        case userID = "user_id"
        case expiresIn = "expires_in"
    }
}
