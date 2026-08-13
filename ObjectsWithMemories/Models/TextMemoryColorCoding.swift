import SwiftUI
import UIKit

/// Encodes a chosen text color into the same .txt file already used for text memories,
/// as a `#RRGGBB` header line — avoids a persistence schema change or a sidecar file.
enum TextMemoryColorCoding {
    static func encode(text: String, color: Color) -> Data {
        Data("#\(color.hexString)\n\(text)".utf8)
    }

    static func decode(_ content: String) -> (text: String, color: Color) {
        let parts = content.split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: false)
        guard let first = parts.first, first.count == 7, first.hasPrefix("#"),
              let color = Color(hex: String(first)) else {
            return (content, .white)
        }
        let rest = parts.count > 1 ? String(parts[1]) : ""
        return (rest, color)
    }
}

extension Color {
    var hexString: String {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }

    init?(hex: String) {
        var hex = hex
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        self = Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}
