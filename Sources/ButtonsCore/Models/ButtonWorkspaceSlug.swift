import Foundation

public enum ButtonWorkspaceSlug {
    public static func make(from value: String) -> String {
        let lowercased = value.lowercased()
        var result = ""
        var lastWasSeparator = false

        for scalar in lowercased.unicodeScalars {
            if CharacterSet.alphanumerics.contains(scalar) {
                result.append(String(scalar))
                lastWasSeparator = false
            } else if !lastWasSeparator {
                result.append("-")
                lastWasSeparator = true
            }
        }

        let trimmed = result.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        return trimmed.isEmpty ? "button" : trimmed
    }
}
