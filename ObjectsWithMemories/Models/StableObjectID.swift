import Foundation
import CryptoKit

enum StableObjectID {
    static func make(from name: String) -> UUID {
        let hash = SHA256.hash(data: Data(name.utf8))
        let hex = hash.prefix(16).map { String(format: "%02x", $0) }.joined()
        let uuidString = [
            hex.prefix(8),
            hex.dropFirst(8).prefix(4),
            hex.dropFirst(12).prefix(4),
            hex.dropFirst(16).prefix(4),
            hex.dropFirst(20)
        ].joined(separator: "-")
        return UUID(uuidString: uuidString) ?? UUID()
    }
}
