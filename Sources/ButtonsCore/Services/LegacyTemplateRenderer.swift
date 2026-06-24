import Foundation

enum LegacyTemplateRenderer {
    static func render(_ template: String, values: [String: String]) -> String {
        values.reduce(template) { partial, entry in
            partial.replacingOccurrences(of: "{{\(entry.key)}}", with: entry.value)
        }
    }
}
